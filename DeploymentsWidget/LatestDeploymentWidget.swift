//
//  DeploymentsWidget.swift
//  DeploymentsWidget
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import WidgetKit
import SwiftUI

let snapshotEntry = WidgetContent(
  title: "Example Deployment",
  author: "Johnny Appleseed",
  project: "example-project",
  status: .building
)

struct LatestDeploymentProvider: TimelineProvider {
  public typealias Entry = WidgetContent
  
  public func getSnapshot(in context: Context, completion: @escaping (WidgetContent) -> Void) {
    completion(snapshotEntry)
  }
  
  public func getTimeline(in context: Context, completion: @escaping (Timeline<WidgetContent>) -> Void) {
    VercelFetcher.shared.loadDeployments { (entries, error) in
      if entries != nil, let entry = entries?[0] {
        let timeline = Timeline(entries: [deploymentToWidget(entry)], policy: .atEnd)
        completion(timeline)
      } else {
        let entry = snapshotEntry
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
      }
    }
  }
  
  public func placeholder(in context: Context) -> WidgetContent {
    return snapshotEntry
  }
}

struct RecentDeploymentsProvider: TimelineProvider {
  public typealias Entry = RecentsTimeline
  
  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    let snapshot = RecentsTimeline(entries: [snapshotEntry])
    completion(snapshot)
  }
  
  public func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    VercelFetcher.shared.loadDeployments { (entries, error) in
      if entries != nil, let entries = entries {
        let widgetContents = entries.map { entry in
          deploymentToWidget(entry)
        }
        
        let timeline = Timeline(entries: [RecentsTimeline(entries: widgetContents)], policy: .atEnd)
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
  var entries: [WidgetContent]
}

struct LatestDeploymentWidget: Widget {
  private let kind: String = "LatestDeploymentWidget"
  
  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: LatestDeploymentProvider()) { entry in
      LatestDeploymentWidgetView(model: entry)
    }
    .supportedFamilies([.systemSmall])
    .configurationDisplayName("Latest Deployment")
    .description("View the most recent Vercel deployment from Zeitgeist")
  }
}

struct RecentDeploymentsWidget: Widget {
  private let kind: String = "RecentDeploymentsWidget"
  
  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: RecentDeploymentsProvider()) { entry in
      RecentDeploymentsWidgetView(entries: entry.entries)
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
    LatestDeploymentWidgetView(model: snapshotEntry)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
