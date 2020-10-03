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
      HStack(alignment: .top) {
        DeploymentStateIndicator(state: deployment.state)
        
        VStack(alignment: .leading) {
          Text(deployment.name)
            .foregroundColor(.secondary)
            .font(.caption)
          
          HStack {
            if deployment.meta.githubCommitMessage != nil, let commitMessage = deployment.meta.githubCommitMessage! {
              Text("\(commitMessage.components(separatedBy: "\n")[0])")
            } else {
              Text("manualDeployment")
            }
          }.lineLimit(2)

          VStack(alignment: .leading, spacing: 2) {
            Text("\(deployment.timestamp, style: .relative) ago")
              .fixedSize()
              .foregroundColor(.secondary)
              .font(.caption)
          }
        }
      }
    }
    .frame(minWidth: 100)
    .listRowInsets(.none)
    .padding(.vertical, 4)
  }
}
