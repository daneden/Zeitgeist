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

struct Provider: TimelineProvider {
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

@main
struct DeploymentsWidget: Widget {
  private let kind: String = "DeploymentsWidget"
  
  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider()) { entry in
      WidgetView(model: entry)
    }
    .supportedFamilies([.systemSmall])
    .configurationDisplayName("Zeitgeist Deployments")
    .description("View the most recent Vercel deployments from Zeitgeist")
  }
}

struct DeploymentsWidget_Previews: PreviewProvider {
  static var previews: some View {
    WidgetView(model: snapshotEntry)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
