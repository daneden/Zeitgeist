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
    let commitMessage: String = deployment.meta.githubCommitMessage ?? "Manual Deploment"
    let firstLine = commitMessage.components(separatedBy: "\n")[0]
    return Group {
      Section(header: Text("Overview").font(Font.caption.bold()).foregroundColor(.secondary)) {
      // MARK: Deployment cause/commit
      VStack(alignment: .leading, spacing: 4) {
        DeploymentStateIndicator(state: deployment.state, verbose: true)
        
        Text(firstLine)
          .font(.headline)
        
        HStack(spacing: 4) {
          Text("\(deployment.timestamp, style: .relative) ago")
          
          Text("•")
          
          if deployment.meta.githubCommitAuthorLogin != nil, let author = deployment.meta.githubCommitAuthorLogin! {
            Text(author).lineLimit(1)
          } else {
            Text(deployment.creator.username)
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
          Text("Copy URL")
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
          URLDetails(deployment: deployment)
          DeploymentDetails(deployment: deployment)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
        Spacer(minLength: 0)
      }
      Spacer(minLength: 0)
    }
    .padding(.all, CGFloat(padding))
    .navigationTitle(Text("Deployment Details"))
  }
}

struct EmptyDeploymentView: View {
  var body: some View {
    return HStack {
      Spacer()
      VStack {
        Spacer()
        Image(systemName: "triangle.circle.fill")
          .imageScale(.large)
          .font(.largeTitle)
        Text("Select a deployment for details")
        Spacer()
      }
      Spacer()
    }.foregroundColor(.secondary)
  }
}
