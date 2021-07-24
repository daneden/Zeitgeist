//
//  LatestDeploymentWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import WidgetKit
import SwiftUI

struct LatestDeploymentEntry: TimelineEntry {
  var date = Date()
  var deployment: Deployment?
  var account: WidgetAccount
}

struct LatestDeploymentProvider: IntentTimelineProvider {
  typealias Entry = LatestDeploymentEntry
  func placeholder(in context: Context) -> LatestDeploymentEntry {
    LatestDeploymentEntry(account: WidgetAccount(identifier: nil, display: "Placeholder Account"))
  }
  
  func getSnapshot(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (LatestDeploymentEntry) -> ()) {
    let loader = DeploymentsLoader()
    
    guard let account = configuration.account,
          let accountId = account.identifier else {
      completion(placeholder(in: context))
      return
    }
    
    loader.loadDeployments(withID: accountId) { result in
      switch result {
      case .success(let deployments):
        if let deployment = deployments.first {
          completion(
            LatestDeploymentEntry(date: deployment.date, deployment: deployment, account: account)
          )
        }
      case .failure(let error):
        print(error)
        return
      }
    }
  }
  
  func getTimeline(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Timeline<LatestDeploymentEntry>) -> ()) {
    let loader = DeploymentsLoader()
    
    guard let account = configuration.account,
          let accountId = account.identifier else {
      completion(
        Timeline(entries: [placeholder(in: context)], policy: .atEnd)
      )
      return
    }
    
    loader.loadDeployments(withID: accountId) { result in
      switch result {
      case .success(let deployments):
        if let deployment = deployments.first {
          completion(
            Timeline(
              entries: [LatestDeploymentEntry(date: deployment.date, deployment: deployment, account: account)],
              policy: .atEnd
            )
          )
        } else {
          completion(Timeline(entries: [], policy: .atEnd))
        }
      case .failure(let error):
        print(error)
        return
      }
    }
  }
}

struct LatestDeploymentWidget: Widget {
  private let kind: String = "LatestDeploymentWidget"
  
  public var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: kind,
      intent: SelectAccountIntent.self,
      provider: LatestDeploymentProvider()
    ) { entry in
      LatestDeploymentWidgetView(config: entry)
    }
    .supportedFamilies([.systemSmall])
    .configurationDisplayName("Latest Deployment")
    .description("View the most recent Vercel deployment")
  }
}

struct LatestDeploymentWidgetView: View {
  var config: LatestDeploymentEntry
  
  var body: some View {
    Link(destination: URL(string: "zeitgeist://open/\(config.account.identifier ?? "0")/\(config.deployment?.id ?? "0")")!) {
      VStack(alignment: .leading) {
        if let deployment = config.deployment {
          DeploymentStateIndicator(state: deployment.state)
            .font(Font.caption.bold())
            .padding(.bottom, 2)
          
          Text(deployment.deploymentCause)
            .font(.subheadline)
            .fontWeight(.bold)
            .lineLimit(3)
            .foregroundColor(.primary)
          
          Text(deployment.date, style: .relative)
            .font(.caption)
          Text(deployment.project)
            .lineLimit(1)
            .font(.caption)
            .foregroundColor(.secondary)
        } else {
          PlaceholderView(forRole: .NoDeployments, alignment: .leading)
            .font(.caption)
        }
        
        Spacer()
        
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          if config.account.identifier != nil {
            Image(systemName: "person.2.fill")
            Text(config.account.displayString)
          } else {
            Text("No Account Selected")
          }
        }.font(.caption2).foregroundColor(.secondary).imageScale(.small).lineLimit(1)
      }
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
