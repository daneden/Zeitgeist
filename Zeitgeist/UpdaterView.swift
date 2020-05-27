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
                Text("\(latestRelease.latestRelease.unsafelyUnwrapped.tag_name) (current version: v\(latestRelease.latestRelease.unsafelyUnwrapped.currentRelease))")
                  .font(.caption)
                  .opacity(0.7)
              }
              Spacer()
            }
              .foregroundColor(.white)
              .contentShape(Rectangle())
          }
          .buttonStyle(PlainButtonStyle())
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.purple)
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
