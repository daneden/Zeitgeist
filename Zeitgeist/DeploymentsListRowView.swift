//
//  DeploymentsListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct DeploymentsListRowView: View {
  var deployment: ZeitDeployment
  @State var timestamp: String? = nil
  @State var isOpen: Bool = false
  @State var isHovered: Bool = false
  
  // We want the timestamp to update in real-time, so let's set up a Timer
  let updateTimestampTimer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
  
  var body: some View {
    VStack {
      Button(action: {self.isOpen.toggle()}) {
        HStack(alignment: .top) {
          Image("chevron")
            .rotationEffect(isOpen ? Angle(degrees: 90.0) : Angle(degrees: 0.0))
            .animation(.interpolatingSpring(stiffness: 200, damping: 12))
            .padding(.top, 4)
          
          // MARK: Main Row
          VStack(alignment: .leading, spacing: 2) {
              VStack(alignment: .leading, spacing: 2) {
                // MARK: Deployment cause/commit
                if(deployment.meta.githubCommitMessage != nil) {
                  Text("\(deployment.meta.githubCommitMessage!.components(separatedBy: "\n")[0])")
                    .fontWeight(.bold)
                    .lineLimit(2)
                } else {
                  Text("Manual Deployment")
                    .fontWeight(.bold)
                }
                
                // MARK: Deployment name/URL
                Button(action: self.openDeployment) {
                  HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(deployment.url)")
                      .lineLimit(1)
                    Image("outbound")
                      .opacity(isHovered ? 1 : 0.5)
                  }
                    .foregroundColor(isHovered ? .accentColor : .secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .toolTip("Open Deployment URL")
                .onHover(perform: { hovered in
                  self.isHovered = hovered
                })
              }
              
              HStack(spacing: 4) {
                Text("\(self.timestamp ?? deployment.relativeTimestamp)")
                  .onReceive(updateTimestampTimer, perform: { _ in
                    self.timestamp = self.deployment.relativeTimestamp
                  })
                  .font(Font.caption.monospacedDigit())
                
                Text("•")
                
                if(deployment.meta.githubCommitAuthorLogin != nil) {
                  Text(deployment.meta.githubCommitAuthorLogin ?? "").lineLimit(1)
                } else {
                  Text(deployment.creator.username)
                }
              }
              .foregroundColor(.secondary)
              .font(.caption)
              .opacity(0.75)
              
            }
            .contentShape(Rectangle())
            Spacer()
            
            DeploymentStateIndicator(state: deployment.state)
              .padding(.top, 2)
        }
        
        // MARK: Details
        if isOpen {
          VStack(alignment: .leading, spacing: 8) {
            Divider()
            if deployment.meta.githubCommitUrl != nil {
              VStack(alignment: .leading, spacing: 4) {
                Button(action: self.openCommitUrl) {
                  Text("View Commit")
                  Text("(\(deployment.meta.githubCommitShortSha!))")
                    .font(.system(.caption, design: .monospaced))
                }
                .buttonStyle(LinkButtonStyle())
                Button(action: self.openInspector) {
                  Text("View Deployment Logs")
                }
                .buttonStyle(LinkButtonStyle())
              }
            } else {
              Button(action: self.openInspector) {
                Text("View Deployment Logs")
              }
              .buttonStyle(LinkButtonStyle())
            }
          }
          .font(.caption)
        }
      }
        .contentShape(Rectangle())
        .buttonStyle(PlainButtonStyle())
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .padding(.bottom, isOpen ? 4 : 0)
    .background(
      Rectangle()
        .fill(Color.primary)
        .opacity(isOpen ? 0.05 : 0).cornerRadius(8)
    )
      .focusable(true) { isFocused in
        print("Focused", isFocused)
    }
    .contextMenu{
      Button(action: self.openDeployment) {
        Text("Open URL")
      }
      
      Button(action: self.copyURL) {
        Text("Copy URL")
      }
      
      Button(action: self.openInspector) {
        Text("View Deployment Logs")
      }
    }
  }
  
  // MARK: Functions
  func openCommitUrl() -> Void {
    if let url = deployment.meta.githubCommitUrl {
      NSWorkspace.shared.open(url)
    }
  }
  
  func openDeployment() -> Void {
    if let url = URL(string: "\(deployment.absoluteURL)") {
      NSWorkspace.shared.open(url)
    }
  }
  
  func openInspector() -> Void {
    if let url = URL(string: "\(deployment.absoluteURL)/_logs") {
      NSWorkspace.shared.open(url)
    }
  }
  
  func copyURL() -> Void {
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(deployment.absoluteURL, forType: .string)
  }
}

struct DeploymentStateIndicator: View {
  var state: ZeitDeploymentState
  var body: some View {
    Group {
      if(state == .queued) {
        Image("clock")
      } else if (state == .error) {
        Image("error")
      } else if (state == .building) {
        ProgressIndicator()
      } else {
        Image("check")
      }
    }
  }
}

//struct DeploymentsListRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        DeploymentsListRowView()
//    }
//}
