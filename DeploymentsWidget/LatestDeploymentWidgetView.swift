//
//  DeploymentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct LatestDeploymentWidgetView: View {
  var config: LatestDeploymentEntry
  
  var body: some View {
    VStack(alignment: .leading) {
      DeploymentStateIndicator(state: config.deployment.state, verbose: true, isWidget: true)
      
      Text(config.deployment.svnInfo?.commitMessage ?? "Manual Deployment")
        .font(.subheadline)
        .fontWeight(.bold)
        .lineLimit(3)
        .foregroundColor(.primary)
      
      Text(config.deployment.date, style: .relative)
        .font(.caption)
      Text(config.deployment.project)
        .lineLimit(1)
        .font(.caption)
        .foregroundColor(.secondary)
      
      Spacer()
      
      HStack(spacing: 2) {
        Image(systemName: "person.2.fill")
        Text(config.team.name)
      }.font(.caption2).foregroundColor(.secondary).imageScale(.small)
      
    }
    .padding()
    .background(Color(TColor.systemBackground))
    .background(LinearGradient(
      gradient: Gradient(
        colors: [Color(TColor.systemBackground), Color(TColor.secondarySystemBackground)]
      ),
      startPoint: .top,
      endPoint: .bottom
    ))
  }
}
