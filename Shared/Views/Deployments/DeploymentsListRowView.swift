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
  var projectName: String?

  var body: some View {
    return VStack(alignment: .leading) {
      HStack(alignment: .top) {
        DeploymentStateIndicator(state: deployment.state)
        
        VStack(alignment: .leading) {
          HStack(spacing: 4) {
            if deployment.target == .production {
              Label("Production Deployment", systemImage: "bolt.fill")
                .labelStyle(IconOnlyLabelStyle())
            }
            
            if let projectName = deployment.project ?? projectName {
              Text(projectName)
            }
          }
          .foregroundColor(.secondary)
          .font(.footnote)
          
          HStack {
            if let commit = deployment.commit, let commitMessage = commit.commitMessageSummary {
              Text(commitMessage)
            } else {
              Text("manualDeployment")
            }
          }.lineLimit(2)

          VStack(alignment: .leading, spacing: 2) {
            Text("\(deployment.date, style: .relative) ago")
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

struct DeploymentListRowView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        DeploymentsListRowView(deployment: ExampleDeployment().deployment!)
      }
    }
}
