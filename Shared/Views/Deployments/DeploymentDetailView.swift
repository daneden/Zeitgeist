//
//  DeploymentDetailView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct DeploymentDetailView: View {
  @EnvironmentObject var session: VercelSession
  
  var accountId: Account.ID { session.accountId! }
  var deployment: Deployment
  
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
  }

  struct Overview: View {
    var deployment: Deployment

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
                  Text("\(deployment.date, style: .relative) ago")
                    .foregroundColor(.secondary)
                    .font(Font.footnote)
                }
              },
              icon: { GitProviderImage(provider: commit.provider).accentColor(.primary) }
            )
          } else {
            VStack(alignment: .leading) {
              Text("Deployed by \(deployment.creator.username)")
              Text("\(deployment.date, style: .relative) ago")
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
            .foregroundStyle(.orange)
            .symbolVariant(.fill)
        }
      }
    }
  }

  struct URLDetails: View {
    var accountId: Account.ID
    var deployment: Deployment

    var body: some View {
      DetailSection(header: Text("Deployment URL")) {
        Link(destination: deployment.url) {
          Label(deployment.url.absoluteString, systemImage: "link").lineLimit(1)
        }.keyboardShortcut("o", modifiers: [.command])

        Button(action: deployment.copyUrl) {
          Label("Copy URL", systemImage: "doc.on.doc")
        }.keyboardShortcut("c", modifiers: [.command])

        AsyncContentView(source: AliasesViewModel(accountId: accountId, deploymentId: deployment.id), placeholderData: []) { aliases in
          DisclosureGroup(content: {
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
          }, label: {
            HStack {
              Label("Deployment Aliases", systemImage: "arrowshape.turn.up.right")
              Spacer()
              Text("\(aliases.count)").foregroundColor(.secondary)
            }
          })

        }
      }
    }
  }

  struct DeploymentDetails: View {
    @Environment(\.presentationMode) var presentationMode
    var accountId: Account.ID
    var deployment: Deployment

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
              primaryButton: .destructive(Text("Delete"), action: deleteDeployment),
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
              primaryButton: .destructive(Text("Cancel Deployment"), action: cancelDeployment),
              secondaryButton: .cancel(Text("Close"))
            )
          }
        }
      }
    }

    func deleteDeployment() {
      do {
        self.mutating = true
        let request = try VercelAPI.request(
          for: .deployments(version: 13, deploymentID: deployment.id),
          with: accountId,
          method: .DELETE
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
          DispatchQueue.main.async {
            self.mutating = false
            #if !os(macOS)
            self.presentationMode.wrappedValue.dismiss()
            #endif
          }
        }.resume()
      } catch {
        print("Error deleting deployment: \(error.localizedDescription)")
        self.mutating = false
      }
    }

    func cancelDeployment() {
      do {
        self.mutating = true
        let request = try VercelAPI.request(
          for: .deployments(version: 12, deploymentID: deployment.id, path: "cancel"),
          with: accountId,
          method: .PATCH
        )

        URLSession.shared.dataTask(with: request) { data, response, error in
          if let response = response as? HTTPURLResponse,
             response.statusCode == 200 {
            DispatchQueue.main.async {
              self.mutating = false
              self.recentlyCancelled = true
            }
          }

          DispatchQueue.main.async {
            self.mutating = false
          }
        }.resume()
      } catch {
        print("Error cancelling deployment: \(error.localizedDescription)")
        self.mutating = false
      }
    }
  }
}

struct DetailSection<Content: View>: View {
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

