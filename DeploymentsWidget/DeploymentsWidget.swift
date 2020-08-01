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
  title: "Test deployment",
  author: "blah",
  project: "This is a plain text description lol",
  status: VercelDeploymentState.building
)

struct Provider: TimelineProvider {
  public typealias Entry = WidgetContent
  
  public func snapshot(with context: Context, completion: @escaping (WidgetContent) -> ()) {
    let entry = snapshotEntry
    completion(entry)
  }
  
  public func timeline(with context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let entries = readContents()
    
    let timeline = Timeline(entries: entries, policy: .atEnd)
    completion(timeline)
  }
}

struct PlaceholderView : View {
  var body: some View {
    DeploymentView(model: snapshotEntry).redacted(reason: .placeholder)
  }
}

@main
struct DeploymentsWidget: Widget {
  private let kind: String = "DeploymentsWidget"
  
  public var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: Provider(), placeholder: PlaceholderView()) { entry in
      DeploymentView(model: entry)
    }
    .supportedFamilies([.systemSmall])
    .configurationDisplayName("Zeitgeist Deployments")
    .description("View the most recent Vercel deployments from Zeitgeist")
  }
}

struct DeploymentsWidget_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentView(model: snapshotEntry)
      .previewContext(WidgetPreviewContext(family: .systemMedium))
  }
}
