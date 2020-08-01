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
    .frame(minWidth: 100)
    .listRowInsets(.none)
    .padding(.vertical, 4)
  }
}
