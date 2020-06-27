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
  @State var timestamp: String?
  @State var isOpen: Bool = false
  @State var isHovered: Bool = false

  // We want the timestamp to update in real-time, so let's set up a Timer
  let updateTimestampTimer = Timer.publish(every: 20, on: .current, in: .common).autoconnect()

  var body: some View {
    return VStack {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 4) {
          // MARK: Deployment cause/commit
          HStack {
            Image(systemName: "chevron.right")
              .rotationEffect(isOpen ? Angle(degrees: 90.0) : Angle(degrees: 0.0))
              .animation(.interpolatingSpring(stiffness: 200, damping: 12))
              .imageScale(.small)
            if deployment.meta.githubCommitMessage != nil {
              Text("\(deployment.meta.githubCommitMessage!.components(separatedBy: "\n")[0])")
            } else {
              Text("manualDeployment")
            }
          }.font(.headline).lineLimit(2)

          // MARK: Deployment name/URL
          Link(destination: URL(string: "\(deployment.absoluteURL)")!) {
            Text("\(deployment.url)")
            Image(systemName: "arrow.up.right.app")
              .imageScale(.small)
          }

          HStack(spacing: 4) {
            Text("\(self.timestamp ?? deployment.relativeTimestamp)")
              .onReceive(updateTimestampTimer, perform: { _ in
                self.timestamp = self.deployment.relativeTimestamp
              })

            Text("•")

            if deployment.meta.githubCommitAuthorLogin != nil {
              Text(deployment.meta.githubCommitAuthorLogin ?? "").lineLimit(1)
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
                Text("viewCommit")
                Text("(\(deployment.meta.githubCommitShortSha!))")
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
