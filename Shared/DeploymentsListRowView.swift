//
//  DeploymentsListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct DeploymentsListRowView: View {
  var deployment: Deployment

  var body: some View {
    return VStack(alignment: .leading) {
      HStack(alignment: .top) {
        DeploymentStateIndicator(state: deployment.state)
        
        VStack(alignment: .leading) {
          Text(deployment.project)
            .foregroundColor(.secondary)
            .font(.caption)
          
          HStack {
            if deployment.svnInfo != nil, let commitMessage = deployment.svnInfo!.commitMessageSummary {
              Text(commitMessage)
            } else {
              Text("manualDeployment")
            }
          }.lineLimit(2)

          VStack(alignment: .leading, spacing: 2) {
            Text("\(deployment.createdAt, style: .relative) ago")
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
