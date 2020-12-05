//
//  DeploymentsWidget.swift
//  DeploymentsWidget
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import WidgetKit
import SwiftUI

let snapshotEntry = Deployment(
  project: "Zeitgeist",
  id: "1",
  createdAt: Date(),
  state: .queued,
  url: URL(string: "https://vercel.com")!,
  creator: VercelDeploymentUser(
    id: "1",
    email: "example@example.com",
    username: "example-user",
    githubLogin: "example_user"
  ),
  svnInfo: nil
)

struct RecentDeploymentsProvider: TimelineProvider {
  public typealias Entry = RecentsTimeline
  
  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    let snapshot = RecentsTimeline(entries: [snapshotEntry])
    completion(snapshot)
  }
  
  public func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    VercelFetcher.shared.loadDeployments { (entries, _) in
      if entries != nil, let entries = entries {
        let timeline = Timeline(entries: [RecentsTimeline(entries: entries)], policy: .atEnd)
        completion(timeline)
      } else {
        let snapshot = RecentsTimeline(entries: [snapshotEntry])
        let timeline = Timeline(entries: [snapshot], policy: .atEnd)
        completion(timeline)
      }
    }
  }
  
  public func placeholder(in context: Context) -> Entry {
    let snapshot = RecentsTimeline(entries: [snapshotEntry, snapshotEntry, snapshotEntry, snapshotEntry])
    return snapshot
  }
}

struct RecentsTimeline: TimelineEntry {
  var date = Date()
  var entries: [Deployment]
}

struct DeploymentTimelineProvider: IntentTimelineProvider {
  func placeholder(in context: Context) -> Deployment {
    return snapshotEntry
  }
  
  func getSnapshot(for configuration: SelectTeamIntent, in context: Context, completion: @escaping (Deployment) -> Void) {
    VercelFetcher.shared.teamId = configuration.team?.identifier
    VercelFetcher.shared.loadDeployments { (entries, _) in
      if entries != nil, let entry = entries?[0] {
        completion(entry)
      } else {
        let entry = snapshotEntry
        completion(entry)
      }
    }
  }
  
  typealias Entry = Deployment
  
  typealias Intent = SelectTeamIntent
  
  func getTimeline(for configuration: SelectTeamIntent, in context: Context, completion: @escaping (Timeline<Deployment>) -> Void) {
    VercelFetcher.shared.teamId = configuration.team?.identifier
    VercelFetcher.shared.loadDeployments { (entries, _) in
      if entries != nil, let entry = entries?[0] {
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      } else {
        let entry = snapshotEntry
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      }
    }
  }
}

struct LatestDeploymentWidget: Widget {
  private let kind: String = "LatestDeploymentWidget"
  
  public var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: kind,
      intent: SelectTeamIntent.self,
      provider: DeploymentTimelineProvider()
    ) { entry in
      LatestDeploymentWidgetView(deployment: entry)
    }
    .supportedFamilies([.systemSmall])
    .configurationDisplayName("Latest Deployment")
    .description("View the most recent Vercel deployment")
  }
}

struct RecentDeploymentsWidget: Widget {
  private let kind: String = "RecentDeploymentsWidget"
  
  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RecentDeploymentsProvider()) { entry in
      RecentDeploymentsWidgetView(deployments: entry.entries)
    }
    .supportedFamilies([.systemLarge])
    .configurationDisplayName("Recent Deployments")
    .description("View recent Vercel deployments from Zeitgeist")
  }
}

@main
struct VercelWidgets: WidgetBundle {
    @WidgetBundleBuilder
    var body: some Widget {
      LatestDeploymentWidget()
      RecentDeploymentsWidget()
    }
}

struct DeploymentsWidget_Previews: PreviewProvider {
  static var previews: some View {
    LatestDeploymentWidgetView(deployment: snapshotEntry)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
