//
//  RecentDeploymentsWidget.swift
//  DeploymentsWidgetExtension
//
//  Created by Daniel Eden on 06/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import WidgetKit
import SwiftUI

struct RecentsTimeline: TimelineEntry {
  var date = Date()
  var deployments: [Deployment]
  var team: VercelTeam?
}

struct RecentDeploymentsProvider: IntentTimelineProvider {
  typealias Entry = RecentsTimeline
  typealias Intent = SelectTeamIntent
  
  let placeholderTimeline = RecentsTimeline(deployments: [exampleDeployment, exampleDeployment, exampleDeployment])
  
  func placeholder(in context: Context) -> RecentsTimeline {
    return placeholderTimeline
  }
  
  func getSnapshot(for configuration: SelectTeamIntent, in context: Context, completion: @escaping (RecentsTimeline) -> Void) {
    let team = VercelTeam(id: configuration.team?.identifier, name: configuration.team?.displayString)
    VercelFetcher.shared.settings.currentTeam = team.id
    VercelFetcher.shared.loadDeployments { (entries, _) in
      if let deployments = entries {
        completion(RecentsTimeline(deployments: deployments, team: team))
      } else {
        completion(placeholderTimeline)
      }
    }
  }
  
  func getTimeline(for configuration: SelectTeamIntent, in context: Context, completion: @escaping (Timeline<RecentsTimeline>) -> Void) {
    let team = VercelTeam(id: configuration.team?.identifier, name: configuration.team?.displayString)
    VercelFetcher.shared.settings.currentTeam = team.id
    
    VercelFetcher.shared.loadDeployments { (entries, _) in
      if let deployments = entries {
        let timeline = Timeline(
          entries: [RecentsTimeline(deployments: deployments, team: team)],
          policy: .atEnd
        )
        
        completion(timeline)
      } else {
        let timeline = Timeline(
          entries: [placeholderTimeline],
          policy: .atEnd
        )
        completion(timeline)
      }
    }
  }
}

struct RecentDeploymentsWidget: Widget {
  private let kind: String = "RecentDeploymentsWidget"
  
  public var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: kind,
      intent: SelectTeamIntent.self,
      provider: RecentDeploymentsProvider()
    ) { config in
      RecentDeploymentsWidgetView(
        deployments: config.deployments,
        team: config.team ?? VercelTeam()
      )
    }
    .supportedFamilies([.systemLarge])
    .configurationDisplayName("Recent Deployments")
    .description("View recent Vercel deployments from Zeitgeist")
  }
}
