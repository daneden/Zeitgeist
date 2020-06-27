//
//  UpdaterView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 26/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct UpdaterView: View {
  @ObservedObject var latestRelease: FetchLatestRelease = FetchLatestRelease()
  
  func releaseView() -> some View {
    let releaseInfo = latestRelease.latestRelease.unsafelyUnwrapped
    
    return Text("\(releaseInfo.tag_name) (current version: v\(releaseInfo.currentRelease))")
      .font(.caption)
      .opacity(0.7)
  }
  
  var body: some View {
    VStack(spacing: 0) {
      if (latestRelease.latestRelease) != nil {
        if latestRelease.latestRelease.unsafelyUnwrapped.isNewerThanCurrentBuild {
          Button(action: self.openLatestRelease) {
            HStack {
              VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 4) {
                  Text("Update Available")
                    .fontWeight(.bold)
                  Image("outbound")
                    .opacity(0.75)
                }
                releaseView()
              }
              Spacer()
            }
              .foregroundColor(.primary)
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.purple)
          .colorScheme(.dark)
          .onHover { hovered in
            if hovered {
              NSCursor.pointingHand.push()
            } else {
              NSCursor.pop()
            }
          }
          Divider()
        }
      }
    }
  }
  
  func openLatestRelease() {
    let url = URL(string: "https://github.com/daneden/zeitgeist/releases/latest")!
    NSWorkspace.shared.open(url)
  }
}

struct UpdaterView_Previews: PreviewProvider {
    static var previews: some View {
        UpdaterView()
    }
}
