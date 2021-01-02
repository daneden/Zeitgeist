//
//  DeploymentDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 26/07/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

#if os(macOS)
typealias Container = ScrollView
#else
typealias Container = Group
#endif

struct DetailSection<Content: View>: View {
  var title: Text?
  var content: Content
  
  init(title: Text? = nil, @ViewBuilder content: () -> Content) {
    self.content = content()
    self.title = title
  }
  
  var body: some View {
    // TODO: Explore using GroupBox for containment in macOS
    //    #if os(macOS)
    //    GroupBox(label: title, content: {
    //      content
    //    })
    //    #else
    Section(header: title) {
      content
    }
    //    #endif
  }
}

// MARK: Deployment cause/commit and status
struct Overview: View {
  var deployment: Deployment
  var projectName: String = "Project"
  
  var body: some View {
    let firstLine = deployment.commit?.commitMessageSummary ?? "Manual Deployment"
    
    return DetailSection {
      DeploymentDetailLabel("Project") {
        Text(deployment.project ?? projectName)
      }
      
      DeploymentDetailLabel("Commit Message") {
        Text(firstLine)
          .lineLimit(3)
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
      
      DeploymentDetailLabel("Deployment Status") {
        HStack {
          DeploymentStateIndicator(state: deployment.state, verbose: true)
          
          if deployment.target == .production {
            Spacer()
            
            HStack(spacing: 2) {
              Image(systemName: "bolt.fill")
              Text("Production")
            }
            .foregroundColor(.secondary)
          }
        }
        .padding(.vertical, 4)
        .font(Font.subheadline.weight(.semibold))
      }
    }
  }
}

// MARK: Deployment name/URL and aliases
struct URLDetails: View {
  @EnvironmentObject var fetcher: VercelFetcher
  var deployment: Deployment
  @State var aliases: [Alias] = []
  @Binding var copied: Bool
  @State var loadingAliases = true
  
  var body: some View {
    return Group {
      #if os(macOS)
      Divider()
        .padding(.bottom, 16)
        .padding(.top, 12)
      #endif
      
      DetailSection(title: Text("Deployment URL")) {
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
        
        DisclosureGroup(
          content: {
            if loadingAliases {
              HStack(spacing: 8) {
                ProgressView()
                Text("Loading")
                  .foregroundColor(.secondary)
              }
            } else if !aliases.isEmpty {
              ForEach(self.aliases, id: \.self) { alias in
                HStack {
                  Link(destination: alias.url) {
                    Text(alias.url.absoluteString).lineLimit(1)
                  }
                  Spacer()
                }
              }
            } else {
              Text("No aliases for deployment found")
                .foregroundColor(.secondary)
            }
          },
          label: {
            HStack {
              Text("Deployment Aliases")
              Spacer()
              Text("\(aliases.count)").foregroundColor(.secondary)
            }
          }
        )
      }
    }
    .onAppear {
      self.loadAliases()
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
  
  func loadAliases() {
    self.fetcher.loadAliases(deploymentId: deployment.id ?? "") { result, error in
      DispatchQueue.main.async {
        self.loadingAliases = false
        if error != nil {
          print(error?.localizedDescription ?? "Error fetching aliases")
          return
        }
        
        if let aliases = result {
          self.aliases = aliases
        }
      }
    }
  }
}

// MARK: Details and links to logs and commit details
struct DeploymentDetails: View {
  var deployment: Deployment
  
  var body: some View {
    return Group {
      #if os(macOS)
      Divider()
        .padding(.bottom, 16)
        .padding(.top, 12)
      #endif
      DetailSection(title: Text("Details")) {
        if let svnInfo = deployment.commit,
           let commitUrl: URL = svnInfo.commitURL,
           let shortSha: String = svnInfo.shortSha {
          Link(destination: commitUrl) {
            Text("View Commit (\(shortSha))")
          }
        }
        
        Link(destination: URL(string: "\(deployment.url.absoluteString)/_logs")!) {
          Text("viewLogs")
        }
      }
    }
  }
}

struct DeploymentDetailView: View {
  var deployment: Deployment
  var projectName: String?
  @State var copied = false
  #if os(macOS)
  let padding = 12.0
  #else
  let padding = 0.0
  #endif
  
  var body: some View {
    return Container {
      HStack {
        VStack {
          Form {
            Overview(deployment: deployment, projectName: projectName ?? deployment.project!)
            URLDetails(deployment: deployment, copied: $copied)
            DeploymentDetails(deployment: deployment)
          }
          Spacer(minLength: 0)
        }
        Spacer(minLength: 0)
      }
      .padding(.all, CGFloat(padding))
      .navigationTitle(Text("Deployment Details"))
      .onChange(of: self.copied) { _ in
        if copied == true {
          DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.copied = false
          }
        }
      }
    }
  }
}
