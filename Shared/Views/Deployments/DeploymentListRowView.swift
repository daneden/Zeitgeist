//
//  DeploymentListRowView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct DeploymentListRowView: View {
  var deployment: VercelDeployment
  var projectName: String?
  
  var body: some View {
    return VStack(alignment: .leading) {
      HStack(alignment: .top) {
        DeploymentStateIndicator(state: deployment.state, style: .compact)
        
        VStack(alignment: .leading) {
          HStack(spacing: 4) {
            if deployment.target == .production {
              Label("Production Deployment", systemImage: "theatermasks")
                .labelStyle(.iconOnly)
                .foregroundStyle(.tint)
                .symbolVariant(.fill)
                .symbolRenderingMode(.hierarchical)
                .imageScale(.small)
            }
            
            Text(deployment.project)
          }
          .font(.footnote.bold())
          
          Text(deployment.deploymentCause.description)
            .lineLimit(2)
          
          VStack(alignment: .leading, spacing: 2) {
            Text("\(deployment.created, style: .relative) ago")
              .fixedSize()
              .foregroundStyle(.secondary)
              .font(.caption)
          }
        }
      }
    }
    .frame(minWidth: 100)
    .listRowInsets(.none)
    .padding(.vertical, 4)
    .transition(.slide)
  }
}
