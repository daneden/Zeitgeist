//
//  DeploymentsListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI
#if !os(macOS)
import UIKit

typealias TColor = UIColor
#else
import AppKit

typealias TColor = NSColor
#endif

struct DeploymentsListRowView: View {
  var deployment: VercelDeployment

  var body: some View {
    return VStack(alignment: .leading) {
      HStack(alignment: .firstTextBaseline) {
        DeploymentStateIndicator(state: deployment.state)
        
        VStack(alignment: .leading) {
          // MARK: Deployment cause/commit
          HStack {
            if deployment.meta.githubCommitMessage != nil, let commitMessage = deployment.meta.githubCommitMessage! {
              Text("\(commitMessage.components(separatedBy: "\n")[0])")
            } else {
              Text("manualDeployment")
            }
          }.font(.subheadline).lineLimit(2)

          HStack(spacing: 4) {
            Text("\(deployment.timestamp, style: .relative) ago")
            Text("•")
            Text(deployment.name)
          }
          .font(.caption)
          .foregroundColor(.secondary)
        }
      }
    }
    .listRowInsets(.none)
    .padding(.vertical, 4)
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
  var verbose: Bool = false
  
  var body: some View {
    HStack(spacing: 4) {
      iconForState(state)
      if verbose {
        Text(labelForState(state))
          .padding(.trailing, 4)
      }
    }
    .padding(.vertical, 1)
    .padding(.horizontal, verbose ? 2 : 1)
    .font(.caption)
    .foregroundColor(colorForState(state))
    .background(colorForState(state).opacity(0.1))
    .cornerRadius(16)
    .padding(.bottom, 4)
  }
  
  func iconForState(_ state: VercelDeploymentState) -> Image {
    switch state {
    case .error:
      return Image(systemName: "exlamationmark.triangle.fill")
    case .building:
      return Image(systemName: "timer")
    case .ready:
      return Image(systemName: verbose ? "checkmark.circle.fill" : "checkmark.circle")
    default:
      return Image(systemName: "hourglass")
    }
  }
  
  func colorForState(_ state: VercelDeploymentState) -> Color {
    switch state {
    case .error:
      return Color(TColor.systemOrange)
    case .building:
      return Color(TColor.systemPurple)
    case .ready:
      return Color(TColor.systemGreen)
    default:
      return Color(TColor.systemGray)
    
    }
  }
  
  func labelForState(_ state: VercelDeploymentState) -> String {
    switch state {
    case .error:
      return "Error building"
    case .building:
      return "Building"
    case .ready:
      return "Deployed"
    default:
      return "Ready"
    
    }
  }
}
