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
      HStack(alignment: .top) {
        // MARK: Main Row
        VStack(alignment: .leading, spacing: 2) {
          VStack(alignment: .leading, spacing: 2) {
            // MARK: Deployment cause/commit
            Button(action: {self.isOpen.toggle()}) {
              HStack(alignment: .top, spacing: 4) {
                Image("chevron")
                  .rotationEffect(isOpen ? Angle(degrees: 90.0) : Angle(degrees: 0.0))
                  .animation(.interpolatingSpring(stiffness: 200, damping: 12))
                  .padding(.top, 4)
                if(deployment.meta.githubCommitMessage != nil) {
                  Text("\(deployment.meta.githubCommitMessage!.components(separatedBy: "\n")[0])")
                    .fontWeight(.bold)
                    .lineLimit(2)
                } else {
                  Text("manualDeployment")
                    .fontWeight(.bold)
                }
              }
            }.buttonStyle(PlainButtonStyle())
            
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
            .toolTip(NSLocalizedString("openDeploymentURL", comment: "Tooltip for a button to open a deployment URL"))
            .onHover(perform: { hovered in
              self.isHovered = hovered
            }).onTapGesture {
              self.openDeployment()
            }.padding(.leading, 12)
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
          .padding(.leading, 12)
          .foregroundColor(.secondary)
          .font(.caption)
          .opacity(0.75)
          
        }
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
                Text("viewCommit")
                Text("(\(deployment.meta.githubCommitShortSha!))")
                  .font(.system(.caption, design: .monospaced))
              }
              .buttonStyle(LinkButtonStyle())
              Button(action: self.openInspector) {
                Text("viewLogs")
              }
              .buttonStyle(LinkButtonStyle())
            }
          } else {
            Button(action: self.openInspector) {
              Text("viewLogs")
            }
            .buttonStyle(LinkButtonStyle())
          }
        }
        .padding(.leading, 12)
        .font(.caption)
      }
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .padding(.bottom, isOpen ? 4 : 0)
    .background(
      Rectangle()
        .fill(Color.primary)
        .opacity(isOpen ? 0.05 : 0).cornerRadius(8)
    )
    .focusable()
    .contextMenu{
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
