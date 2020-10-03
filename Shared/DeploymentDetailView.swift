//
//  DeploymentDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 26/07/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct Overview: View {
  var deployment: VercelDeployment
  
  var body: some View {
    let commitMessage: String = deployment.meta.githubCommitMessage ?? "Manual Deployment"
    let firstLine = commitMessage.components(separatedBy: "\n")[0]
    
    let extra = commitMessage.components(separatedBy: "\n").dropFirst().joined(separator: "\n")
    return Group {
      Section(header: Text("Overview").font(Font.caption.bold()).foregroundColor(.secondary)) {
      // MARK: Deployment cause/commit
      VStack(alignment: .leading, spacing: 4) {
        DeploymentStateIndicator(state: deployment.state, verbose: true)
        
        Text(deployment.name)
          .font(.footnote)
          .foregroundColor(.secondary)
        
        Text(firstLine)
          .font(.headline)
        
        Text("\(deployment.timestamp, style: .relative) ago")
          .fixedSize()
          .font(.caption)
          .foregroundColor(.secondary)
        
        Text(extra).font(.footnote).lineLimit(10)
        
          
        Group {
          if deployment.meta.githubCommitAuthorLogin != nil, let author = deployment.meta.githubCommitAuthorLogin! {
            Text("Author: \(author)").lineLimit(1)
          } else {
            Text("Author: \(deployment.creator.username)")
          }
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }.padding(.vertical, 8)
    }
    }
  }
}

struct URLDetails: View {
  var deployment: VercelDeployment
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
        Link(destination: URL(string: deployment.absoluteURL)!) {
          Text("\(deployment.url)").lineLimit(1)
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
    pasteboard.string = deployment.absoluteURL
    #else
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
    pasteboard.setString(deployment.absoluteURL, forType: NSPasteboard.PasteboardType.string)
    #endif
  
    copied = true
  }
}


struct DeploymentDetails: View {
  var deployment: VercelDeployment
  
  var body: some View {
    return Group {
      #if os(macOS)
      Divider()
        .padding(.bottom, 16)
        .padding(.top, 12)
      #endif
      Section(header: Text("Details").font(Font.caption.bold()).foregroundColor(.secondary)) {
        // MARK: Details
        if let commitUrl: URL = deployment.meta.githubCommitUrl,
           let shortSha: String = deployment.meta.githubCommitShortSha {
          Link(destination: commitUrl) {
            Text("View Commit (\(shortSha))")
          }
        }
        
        Link(destination: URL(string: "\(deployment.absoluteURL)/_logs")!) {
          Text("viewLogs")
        }
      }
    }
  }
}

struct DeploymentDetailView: View {
  var deployment: VercelDeployment
  @State var copied = false
  #if os(macOS)
  let padding = 12.0
  #else
  let padding = 0.0
  #endif
  
  var body: some View {
    return HStack {
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
    .onChange(of: self.copied) { value in
      if copied == true {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
          self.copied = false
        }
      }
    }
  }
}

struct DeploymentDetailView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentDetailView(deployment: mockDeployment)
  }
}
