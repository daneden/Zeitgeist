//
//  DeploymentsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

#if os(macOS)
typealias ZGDeploymentsListStyle = SidebarListStyle
#else
typealias ZGDeploymentsListStyle = PlainListStyle
#endif

struct DeploymentsListView: View {
  @EnvironmentObject var settings: UserDefaultsManager
  @EnvironmentObject var vercelFetcher: VercelFetcher
  @State var team: VercelTeam = VercelTeam()
  
  var body: some View {
    let deployments = vercelFetcher.deploymentsStore.deployments[team.id] ?? []
    return Group {
      if deployments.isEmpty {
        if vercelFetcher.fetchState == .loading {
          ProgressView("Loading deployments...")
        } else {
          VStack(spacing: 0) {
            Spacer()
            Text("emptyState")
              .foregroundColor(.secondary)
            Spacer()
          }
        }
      } else {
        List(deployments, id: \.self) { deployment in
          NavigationLink(destination: DeploymentDetailView(deployment: deployment)) {
            DeploymentsListRowView(deployment: deployment)
              .id(deployment.id)
          }
        }
        .listStyle(ZGDeploymentsListStyle())
      }
    }
    .navigationTitle(Text("Deployments"))
    .toolbar {
      ToolbarItem(placement: .status) {
        Text(team.name)
          .font(.caption)
          .foregroundColor(.secondary)
      }
    }
    .onAppear {
      vercelFetcher.tick()
    }
  }
}

struct DeploymentsListView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentsListView()
  }
}
