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

struct Overview: View {
  var deployment: Deployment
  
  var body: some View {
    let firstLine = deployment.commit?.commitMessageSummary ?? "Manual Deployment"
    
    return Group {
      Section(header: Text("Overview").font(Font.caption.bold()).foregroundColor(.secondary)) {
        // MARK: Deployment cause/commit
        VStack(alignment: .leading) {
          DeploymentStateIndicator(state: deployment.state, verbose: true)
          
          Text(deployment.project)
            .font(.footnote)
            .foregroundColor(.secondary)
          
          Text(firstLine)
            .font(.headline)
          
          Text("\(deployment.date, style: .relative) ago")
            .fixedSize()
            .font(.caption)
            .foregroundColor(.secondary)
          
          HStack {
            if let commit = deployment.commit {
              GitProviderImage(provider: commit.provider)
              Text("\(commit.commitAuthorName)").lineLimit(1)
            } else {
              Text("Deployed by \(deployment.creator.username)")
                .padding(.top, 4)
            }
          }
        }.padding(.vertical, 8)
      }
    }
  }
}

struct URLDetails: View {
  var deployment: Deployment
  @Binding var copied: Bool
  
  var body: some View {
    return Group {
      #if os(macOS)
      Divider()
        .padding(.bottom, 16)
        .padding(.top, 12)
      #endif
      
      Section(header: Text("Deployment URL").font(Font.caption.bold()).foregroundColor(.secondary)) {
        // MARK: Deployment name/URL
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
    return Group {
      #if os(macOS)
      Divider()
        .padding(.bottom, 16)
        .padding(.top, 12)
      #endif
      Section(header: Text("Details").font(Font.caption.bold()).foregroundColor(.secondary)) {
        // MARK: Details
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
            Overview(deployment: deployment)
            URLDetails(deployment: deployment, copied: $copied)
            DeploymentDetails(deployment: deployment)
          }.frame(maxWidth: .infinity, maxHeight: .infinity)
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

//struct DeploymentDetailView_Previews: PreviewProvider {
//  static var previews: some View {
//    DeploymentDetailView(deployment: mockDeployment)
//  }
//}
