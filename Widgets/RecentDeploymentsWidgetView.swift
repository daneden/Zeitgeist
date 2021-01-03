//
//  RecentDeploymentsWidgetView.swift
//  iOS
//
//  Created by Daniel Eden on 03/10/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct RecentDeploymentsWidgetView: View {
  var deployments: [Deployment]
  var team: VercelTeam
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Recent deployments")
          .font(.footnote).fontWeight(.semibold)
      
        if let currentTeam = team {
          Spacer()
          HStack(spacing: 2) {
            Image(systemName: "person.2.fill")
            Text(currentTeam.name)
          }.font(.footnote).foregroundColor(.secondary).imageScale(.small).lineLimit(1)
        }
      }
      
      Divider().padding(.bottom, 4)
      
      if !deployments.isEmpty {
        ForEach(deployments.prefix(6), id: \.self) { deployment in
          Link(destination: URL(string: "zeitgeist://deployment/\(team.id)/\(deployment.id)")!) {
            HStack(alignment: .top) {
              DeploymentStateIndicator(state: deployment.state, verbose: false)
            
              VStack(alignment: .leading) {
                Text(deployment.commit?.commitMessage ?? "Manual Deployment")
                  .fontWeight(.bold)
                  .lineLimit(3)
                  .foregroundColor(.primary)
                
                Text("\(deployment.project), \(deployment.date, style: .relative) ago")
                    .foregroundColor(.secondary)
              }
              
              Spacer()
            }
            .padding(.bottom, 4)
            .font(.footnote)
          }
        }
      } else {
        VStack {
          Spacer()
          Text("No Deployments Found")
            .font(.footnote)
            .foregroundColor(.secondary)
          Spacer()
        }
        .frame(minWidth: 0, maxWidth: .infinity)
      }
      
      Spacer()
    }
    .padding()
    .background(Color.systemBackground)
    .background(LinearGradient(
                  gradient: Gradient(
                    colors: [.systemBackground, .secondarySystemBackground]
                  ),
                  startPoint: .top,
                  endPoint: .bottom
    ))
  }
}

struct RecentDeploymentsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
      RecentDeploymentsWidgetView(
        deployments: [exampleDeployment, exampleDeployment],
        team: VercelTeam()
      )
    }
}
