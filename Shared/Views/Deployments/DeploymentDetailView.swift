//
//  DeploymentDetailView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct DeploymentDetailView: View {
  @EnvironmentObject var session: VercelSession
  
  var accountId: VercelAccount.ID { session.accountId }
  @State var deployment: VercelDeployment
  
  var body: some View {
    Form {
      Overview(deployment: deployment)
      URLDetails(accountId: accountId, deployment: deployment)
      DeploymentDetails(accountId: accountId, deployment: deployment)
        .symbolRenderingMode(.multicolor)
    }
    .symbolRenderingMode(.hierarchical)
    .navigationTitle("Deployment Details")
    .makeContainer()
    .dataTask {
      try? await loadDeploymentDetails()
    }
  }
  
  private func loadDeploymentDetails() async throws {
    var request = VercelAPI.request(for: .deployments(deploymentID: deployment.id), with: session.accountId)
    try session.signRequest(&request)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(VercelDeployment.self, from: data)
    deployment = decoded
  }
}

fileprivate struct Overview: View {
  var deployment: VercelDeployment
  
  var body: some View {
    DetailSection(header: Text("Overview")) {
      LabelView("Project") {
        Text(deployment.project)
      }
      
      LabelView("Commit Message") {
        Text(deployment.deploymentCause)
          .font(.headline)
      }
      
      LabelView("Author") {
        if let commit = deployment.commit {
          Label(
            title: {
              VStack(alignment: .leading) {
                Text("\(commit.commitAuthorName)").lineLimit(1)
                Text("\(deployment.created, style: .relative) ago")
                  .foregroundColor(.secondary)
                  .font(Font.footnote)
              }
            },
            icon: { GitProviderImage(provider: commit.provider).accentColor(.primary) }
          )
        } else {
          VStack(alignment: .leading) {
            Text("Deployed by \(deployment.creator.username)")
            Text("\(deployment.created, style: .relative) ago")
              .foregroundColor(.secondary)
              .font(.footnote)
          }
        }
      }
      
      LabelView("Status") {
        DeploymentStateIndicator(state: deployment.state)
      }
      
      if deployment.target == .production {
        Label("Production Deployment", systemImage: "theatermasks")
          .symbolVariant(.fill)
      }
    }
  }
}

fileprivate struct URLDetails: View {
  @EnvironmentObject var session: VercelSession
  
  var accountId: VercelAccount.ID
  var deployment: VercelDeployment
  
  @State private var aliases: [VercelAlias] = []
  
  var body: some View {
    DetailSection(header: Text("Deployment URL")) {
      Link(destination: deployment.url) {
        Label(deployment.url.absoluteString, systemImage: "link").lineLimit(1)
      }.keyboardShortcut("o", modifiers: [.command])
      
      Button(action: deployment.copyUrl) {
        Label("Copy URL", systemImage: "doc.on.doc")
      }.keyboardShortcut("c", modifiers: [.command])
      
      
      DisclosureGroup {
        if aliases.isEmpty {
          Text("No aliases assigned to deployment")
            .foregroundColor(.secondary)
        } else {
          ForEach(aliases, id: \.self) { alias in
            HStack {
              Link(destination: alias.url) {
                Text(alias.url.absoluteString).lineLimit(1)
              }
              Spacer()
            }
          }
        }
      } label: {
        HStack {
          Label("Deployment Aliases", systemImage: "arrowshape.turn.up.right")
          Spacer()
          Text("\(aliases.count)").foregroundColor(.secondary)
        }
      }
      .task {
        do {
          var request = VercelAPI.request(
            for: .deployments(
              version: 5,
              deploymentID: deployment.id,
              path: "aliases"
            ),
            with: accountId
          )
          try session.signRequest(&request)
          let (data, _) = try await URLSession.shared.data(for: request)
          try withAnimation {
            aliases = try JSONDecoder().decode(VercelAlias.APIResponse.self, from: data).aliases
          }
        } catch {
          print(error)
        }
      }
    }
  }
}

fileprivate struct DeploymentDetails: View {
  @Environment(\.presentationMode) var presentationMode
  @EnvironmentObject var session: VercelSession
  
  var accountId: VercelAccount.ID
  var deployment: VercelDeployment
  
  @State var cancelConfirmation = false
  @State var deleteConfirmation = false
  @State var redeployConfirmation = false
  
  @State var mutating = false
  @State var recentlyCancelled = false
  
  var body: some View {
    DetailSection(header: Text("Details")) {
      if let svnInfo = deployment.commit,
         let commitUrl: URL = svnInfo.commitUrl,
         let shortSha: String = svnInfo.shortSha {
        Link(destination: commitUrl) {
          Label(
            title: { Text("View Commit (\(shortSha))") },
            icon: { GitProviderImage(provider: svnInfo.provider) }
          )
        }
      }
      
      NavigationLink(destination: DeploymentLogView(deployment: deployment, accountID: accountId)) {
        Label("View Logs", systemImage: "terminal")
      }
      
      if (deployment.state != .queued && deployment.state != .building)
          || deployment.state == .cancelled
          || recentlyCancelled {
        Button(role: .destructive, action: { deleteConfirmation = true }) {
          HStack {
            Label("Delete Deployment", systemImage: "trash")
          }
        }
        .alert(isPresented: $deleteConfirmation) {
          Alert(
            title: Text("Are you sure you want to delete this deployment?"),
            message: Text("Deleting this deployment might break links used in integrations, such as the ones in the pull requests of your Git provider. This action cannot be undone."),
            primaryButton: .destructive(Text("Delete"), action: {
              Task { await deleteDeployment() }
            }),
            secondaryButton: .cancel()
          )
        }
        .disabled(mutating)
      } else {
        Button(role: .destructive, action: { cancelConfirmation = true }) {
          HStack {
            Label("Cancel Deployment", systemImage: "xmark")
            
            if mutating {
              Spacer()
              ProgressView()
            }
          }
        }
        .disabled(mutating)
        .alert(isPresented: $cancelConfirmation) {
          Alert(
            title: Text("Are you sure you want to cancel this deployment?"),
            message: Text("This will immediately stop the build, with no option to resume."),
            primaryButton: .destructive(Text("Cancel Deployment"), action: {
              Task { await cancelDeployment() }
            }),
            secondaryButton: .cancel(Text("Close"))
          )
        }
      }
    }
  }
  
  func deleteDeployment() async {
    self.mutating = true
    
    do {
      var request = VercelAPI.request(
        for: .deployments(version: 13, deploymentID: deployment.id),
        with: accountId,
        method: .DELETE
      )
      try session.signRequest(&request)
      
      let (_, response) = try await URLSession.shared.data(for: request)
      
      if let response = response as? HTTPURLResponse,
         response.statusCode == 200 {
        #if !os(macOS)
        self.presentationMode.wrappedValue.dismiss()
        #endif
      }
    } catch {
      print("Error deleting deployment: \(error.localizedDescription)")
    }
    
    self.mutating = false
  }
  
  func cancelDeployment() async {
    self.mutating = true
    
    do {
      var request = VercelAPI.request(
        for: .deployments(version: 12, deploymentID: deployment.id, path: "cancel"),
        with: accountId,
        method: .PATCH
      )
      try session.signRequest(&request)
      
      let (_, response) = try await URLSession.shared.data(for: request)
      
      if let response = response as? HTTPURLResponse,
         response.statusCode == 200 {
        self.recentlyCancelled = true
      }
    } catch {
      print("Error cancelling deployment: \(error.localizedDescription)")
    }
    
    self.mutating = false
  }
}

fileprivate struct DetailSection<Content: View>: View {
  var header: Text
  var content: Content

  init(header: Text, @ViewBuilder content: @escaping () -> Content) {
    self.content = content()
    self.header = header
  }

  var body: some View {
    #if os(macOS)
    GroupBox(label: header) {
      HStack {
        VStack(alignment: .leading) {
          content
        }
        Spacer(minLength: 0)
      }
      .padding()
    }
    #else
    Section(header: header) {
      content
    }
    #endif
  }
}

