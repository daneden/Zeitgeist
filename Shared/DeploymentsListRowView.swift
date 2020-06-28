//
//  DeploymentsListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct DeploymentsListRowView: View {
  var deployment: VercelDeployment
  @State var isOpen: Bool = false
  @State var isHovered: Bool = false

  var body: some View {
    return VStack {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          // MARK: Deployment cause/commit
          HStack {
            Image(systemName: "chevron.right")
              .rotationEffect(isOpen ? Angle(degrees: 90.0) : Angle(degrees: 0.0))
              .imageScale(.small)
            if deployment.meta.githubCommitMessage != nil, let commitMessage = deployment.meta.githubCommitMessage! {
              Text("\(commitMessage.components(separatedBy: "\n")[0])")
            } else {
              Text("manualDeployment")
            }
          }.font(.headline).lineLimit(1)

          // MARK: Deployment name/URL
          Link(destination: URL(string: "\(deployment.absoluteURL)")!) {
            HStack {
              Text("\(deployment.url)")
              Image(systemName: "arrow.up.right.app")
                .imageScale(.small)
            }
          }

          HStack(spacing: 4) {
            Text("\(deployment.timestamp, style: .relative) ago")

            Text("•")

            if deployment.meta.githubCommitAuthorLogin != nil, let author = deployment.meta.githubCommitAuthorLogin! {
              Text(author).lineLimit(1)
            } else {
              Text(deployment.creator.username)
            }
          }
          .foregroundColor(.secondary)

        }
        Spacer()

        DeploymentStateIndicator(state: deployment.state)
      }.contentShape(Rectangle())
      .onTapGesture {
        self.isOpen.toggle()
      }

      // MARK: Details
      if isOpen {
        VStack(alignment: .leading, spacing: 8) {
          Divider()
          if deployment.meta.githubCommitUrl != nil {
            VStack(alignment: .leading, spacing: 4) {
              Button(action: self.openCommitUrl) {
                Text("View Commit (\(deployment.meta.githubCommitShortSha!))")
              }
              Button(action: self.openInspector) {
                Text("viewLogs")
              }
            }
          } else {
            Button(action: self.openInspector) {
              Text("viewLogs")
            }
          }
        }.buttonStyle(ZeitgeistButtonStyle())
      }
    }
    .padding(.all, 8)
    .background(Color.secondary.opacity(isOpen ? 0.1 : 0))
    .cornerRadius(6.0)
    .contextMenu {
      Button(action: self.openDeployment) {
        Text("openURL")
      }

      Button(action: self.copyURL) {
        Text("copyURL")
      }

      Button(action: self.openInspector) {
        Text("viewLogs")
      }
    }
  }

  // MARK: Functions
  func openCommitUrl() {
    if let url = deployment.meta.githubCommitUrl {
      #if os(macOS)
      NSWorkspace.shared.open(url)
      #endif
    }
  }

  func openDeployment() {
    if let url = URL(string: "\(deployment.absoluteURL)") {
      #if os(macOS)
      NSWorkspace.shared.open(url)
      #endif
    }
  }

  func openInspector() {
    if let url = URL(string: "\(deployment.absoluteURL)/_logs") {
      #if os(macOS)
      NSWorkspace.shared.open(url)
      #endif
    }
  }

  func copyURL() {
    #if os(macOS)
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(deployment.absoluteURL, forType: .string)
    #endif
  }
}

struct DeploymentStateIndicator: View {
  var state: VercelDeploymentState
  var body: some View {
    Group {
      if state == .queued {
        Image(systemName: "hourglass")
          .foregroundColor(.secondary)
      } else if state == .error {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundColor(.orange)
      } else if state == .building {
        Image(systemName: "timer")
          .foregroundColor(.secondary)
      } else {
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(.green)
      }
    }
  }
}
