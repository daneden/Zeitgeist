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
        
        VStack(alignment: .leading, spacing: 2) {
          Text("\(deployment.timestamp, style: .relative) ago")
            .fixedSize()
          
          Group {
            if deployment.meta.githubCommitAuthorLogin != nil, let author = deployment.meta.githubCommitAuthorLogin! {
              Text(author).lineLimit(1)
            } else {
              Text(deployment.creator.username)
            }
          }.foregroundColor(.secondary)
        }
        .font(.caption)
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
    copied.toggle()
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
  @State var copied = false {
    didSet {
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        copied = false
      }
    }
  }
  #if os(macOS)
  let padding = 12.0
  #else
  let padding = 0.0
  #endif
  
  var body: some View {
    return ZStack(alignment: .bottom) {
      HStack {
        VStack {
          Form {
            Overview(deployment: deployment)
            URLDetails(deployment: deployment, copied: Binding(
                        get: { self.copied },
                        set: { (newValue) in
                          self.copied = newValue
                          if newValue == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                              self.copied = false
                            }
                          }
                        }))
            DeploymentDetails(deployment: deployment)
          }.frame(maxWidth: .infinity, maxHeight: .infinity)
          Spacer(minLength: 0)
        }
        Spacer(minLength: 0)
      }
      .padding(.all, CGFloat(padding))
      .navigationTitle(Text("Deployment Details"))
      
      #if os(iOS)
      Group {
        HStack {
          Image(systemName: "checkmark")
          Text("Copied to clipboard")
        }
          .padding()
          .background(Color(TColor.tertiarySystemBackground))
          .background(VisualEffectView(effect: UIBlurEffect.init(style: .systemThinMaterial)))
          .foregroundColor(Color(TColor.secondaryLabel))
          .cornerRadius(44)
      }
      .opacity(copied ? 1.0 : 0.0)
      .offset(x: 0, y: copied ? 0.0 : 100)
      .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.8))
      #endif
    }
  }
}

struct DeploymentDetailView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentDetailView(deployment: mockDeployment)
  }
}
