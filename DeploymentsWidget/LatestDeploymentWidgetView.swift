//
//  DeploymentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct LatestDeploymentWidgetView: View {
  var deployment: Deployment
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    VStack(alignment: .leading) {
      DeploymentStateIndicator(state: deployment.state, verbose: true, isWidget: true)
      
      Text(deployment.svnInfo?.commitMessage ?? "Manual Deployment")
        .font(.subheadline)
        .fontWeight(.bold)
        .lineLimit(3)
        .foregroundColor(.primary)
      Text(deployment.date, style: .relative)
        .font(.caption)
        .foregroundColor(.secondary)
      
      Spacer()
      
      Text("\(deployment.project)")
        .font(.caption).font(.caption)
      
    }
    .padding()
    .background(Color(TColor.systemBackground))
  }
}
