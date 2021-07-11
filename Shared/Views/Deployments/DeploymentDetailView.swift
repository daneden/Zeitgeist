//
//  DeploymentDetailView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct DeploymentDetailView: View {
  var accountId: Account.ID
  var deployment: Deployment
  @State var copiedURL = false
  
  var body: some View {
    Form {
      Overview(deployment: deployment)
      URLDetails(copied: $copiedURL, accountId: accountId, deployment: deployment)
      DeploymentDetails(accountId: accountId, deployment: deployment)
    }
    .navigationTitle("Deployment Details")
    .onChange(of: self.copiedURL) { _ in
      if copiedURL == true {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.copiedURL = false
        }
      }
    }
    .makeContainer()
  }
  
  struct Overview: View {
    var deployment: Deployment
    
    var body: some View {
      Section(header: Text("Overview")) {
        DeploymentDetailLabel("Project") {
          Text(deployment.project)
        }
        
        DeploymentDetailLabel("Commit Message") {
          Text(deployment.deploymentCause)
            .font(.headline)
        }
        
        DeploymentDetailLabel("Author") {
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
        
        DeploymentDetailLabel("Status") {
          DeploymentStateIndicator(state: deployment.state)
        }
        
        if deployment.target == .production {
          Label("Production Build", systemImage: "bolt.fill")
            .foregroundColor(.systemOrange)
        }
      }
    }
  }
  
  struct URLDetails: View {
    @Binding var copied: Bool
    @State var aliasesVisible = false
    
    var accountId: Account.ID
    var deployment: Deployment
    
    var body: some View {
      Section(header: Text("Deployment URL")) {
        Link(destination: deployment.url) {
          Label(deployment.url.absoluteString, systemImage: "link").lineLimit(1)
        }.keyboardShortcut("o", modifiers: [.command])
        
        Button(action: self.copyUrl) {
          Label(copied ? "Copied" : "Copy URL", systemImage: "doc.on.doc")
        }.keyboardShortcut("c", modifiers: [.command])
        
        AsyncContentView(source: AliasesViewModel(accountId: accountId, deploymentId: deployment.id), placeholderData: []) { aliases in
          DisclosureGroup(isExpanded: $aliasesVisible, content: {
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
            .contentShape(Rectangle())
            .onTapGesture {
              withAnimation { self.aliasesVisible.toggle() }
            }
          })
          
        }
      }
    }
    
    func copyUrl() {
      #if os(iOS)
      let pasteboard = UIPasteboard.general
      pasteboard.string = deployment.url.absoluteString
      #else
      let pasteboard = NSPasteboard.general
      pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
      pasteboard.setString(deployment.url.absoluteString, forType: NSPasteboard.PasteboardType.string)
      #endif
      
      copied = true
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
      Section(header: Text("Details")) {
        if let svnInfo = deployment.commit,
           let commitUrl: URL = svnInfo.commitURL,
           let shortSha: String = svnInfo.shortSha {
          Link(destination: commitUrl) {
            Label(
              title: { Text("View Commit (\(shortSha))") },
              icon: { GitProviderImage(provider: svnInfo.provider) }
            )
          }
        }
        
        Link(destination: URL(string: "\(deployment.url.absoluteString)/_logs")!) {
          Label("View Logs", systemImage: "terminal")
        }.keyboardShortcut("o", modifiers: [.command, .shift])
        
        if (deployment.state != .queued && deployment.state != .building)
            || deployment.state == .cancelled
            || recentlyCancelled {
          // MARK: Stub code for redeployments
//          Button(action: { redeployConfirmation = true }) {
//            Label("Redeploy", systemImage: "arrow.clockwise")
//          }
//          .alert(isPresented: $redeployConfirmation) {
//            Alert(
//              title: Text("Confirm Redeployment"),
//              message: Text("This will create a new Deployment with the same source code as your current Deployment, but with the newest configuration from your Project Settings."),
//              primaryButton: .default(Text("Redeploy"), action: redeploy),
//              secondaryButton: .cancel()
//            )
//          }
//          .disabled(mutating)
          
          Button(action: { deleteConfirmation = true }) {
            HStack {
              Label("Delete Deployment", systemImage: "trash")
                .foregroundColor(mutating ? .secondary : .systemRed)
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
          Button(action: { cancelConfirmation = true }) {
            HStack {
              Label("Cancel Deployment", systemImage: "xmark")
                .foregroundColor(mutating ? .secondary : .systemRed)
              
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
    
    // Stub code for redeployments
    func redeploy() {
      do {
        self.mutating = true
        var request = try VercelAPI.request(
          for: .deploymentsV12,
          with: accountId,
          method: .POST
        )
        
        if let commit = deployment.commit {
          let data: [String: Any] = [
            "meta": AnyCommit.encodeToDictionary(from: commit),
            "files": [],
            "name": deployment.project
          ]
          
          request.httpBody = try JSONSerialization.data(withJSONObject: data)
          print(String(decoding: request.httpBody!, as: UTF8.self))
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
          DispatchQueue.main.async {
            self.mutating = false
            self.presentationMode.wrappedValue.dismiss()
          }
        }.resume()
      } catch {
        print(error.localizedDescription)
        self.mutating = false
      }
    }
    
    func deleteDeployment() {
      do {
        self.mutating = true
        let request = try VercelAPI.request(
          for: .deploymentsV11,
          with: accountId,
          appending: "\(deployment.id)",
          method: .DELETE
        )
        
        URLSession.shared.dataTask(with: request) { data, response, error in
          DispatchQueue.main.async {
            self.mutating = false
            self.presentationMode.wrappedValue.dismiss()
          }
        }.resume()
      } catch {
        print(error.localizedDescription)
        self.mutating = false
      }
    }
    
    func cancelDeployment() {
      do {
        self.mutating = true
        let request = try VercelAPI.request(
          for: .deploymentsV12,
          with: accountId,
          appending: "\(deployment.id)/cancel",
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
        print(error.localizedDescription)
        self.mutating = false
      }
    }
  }
}
