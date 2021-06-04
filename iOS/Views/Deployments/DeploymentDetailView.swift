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
      DeploymentDetails(deployment: deployment)
    }
    .navigationTitle("Deployment Details")
    .onChange(of: self.copiedURL) { _ in
      if copiedURL == true {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.copiedURL = false
        }
      }
    }
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
              icon: { GitProviderImage(provider: commit.provider) }
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
          HStack {
            DeploymentStateIndicator(state: deployment.state)
            
            if deployment.target == .production {
              Spacer()
              
              HStack(spacing: 2) {
                Image(systemName: "bolt.fill")
                Text("Production")
              }
              .foregroundColor(.secondary)
            }
          }
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
          Text(deployment.url.absoluteString).lineLimit(1)
        }
        
        Button(action: self.copyUrl) {
          HStack {
            Text(copied ? "Copied" : "Copy URL")
            Spacer()
            Image(systemName: "doc.on.doc")
          }
        }
        
        AsyncContentView(source: AliasesViewModel(accountId: accountId, deploymentId: deployment.id)) { aliases in
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
              Text("Deployment Aliases")
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
    var deployment: Deployment
    var body: some View {
      Section(header: Text("Details")) {
        if let svnInfo = deployment.commit,
           let commitUrl: URL = svnInfo.commitURL,
           let shortSha: String = svnInfo.shortSha {
          Link(destination: commitUrl) {
            Text("View Commit (\(shortSha))")
          }
        }
        
        Link(destination: URL(string: "\(deployment.url.absoluteString)/_logs")!) {
          Text("View Logs")
        }
      }
    }
  }
}
