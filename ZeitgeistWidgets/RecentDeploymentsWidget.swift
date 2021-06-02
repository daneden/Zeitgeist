//
//  RecentDeploymentstWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import WidgetKit
import SwiftUI

struct RecentDeploymentsEntry: TimelineEntry {
  var date = Date()
  var deployments: [Deployment]?
  var account: WidgetAccount
}

struct RecentDeploymentsProvider: IntentTimelineProvider {
  typealias Entry = RecentDeploymentsEntry
  func placeholder(in context: Context) -> Entry {
    Entry(account: WidgetAccount(identifier: nil, display: "Placeholder Account"))
  }
  
  func getSnapshot(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Entry) -> ()) {
    let loader = DeploymentsLoader()
    loader.useURLCache = false
    
    guard let account = configuration.account,
          let accountId = account.identifier else {
      completion(placeholder(in: context))
      return
    }
    
    loader.loadDeployments(withID: accountId) { result in
      switch result {
      case .success(let deployments):
        completion(Entry(deployments: deployments, account: account))
      case .failure(let error):
        print(error)
        return
      }
    }
  }
  
  func getTimeline(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    let loader = DeploymentsLoader()
    loader.useURLCache = false
    print(context.isPreview)
    
    guard let account = configuration.account,
          let accountId = account.identifier else {
      completion(Timeline(entries: [placeholder(in: context)], policy: .atEnd))
      return
    }
    
    loader.loadDeployments(withID: accountId) { result in
      switch result {
      case .success(let deployments):
        DispatchQueue.main.async {
          completion(
            Timeline(
              entries: [Entry(deployments: deployments, account: account)],
              policy: .atEnd
            )
          )
        }
      case .failure(let error):
        print(error)
        return
      }
    }
  }
}

struct RecentDeploymentsWidget: Widget {
  private let kind: String = "RecentDeploymentsWidget"
  
  public var body: some WidgetConfiguration {
    IntentConfiguration(
      kind: kind,
      intent: SelectAccountIntent.self,
      provider: RecentDeploymentsProvider()
    ) { entry in
      RecentDeploymentsWidgetView(config: entry)
    }
    .supportedFamilies([.systemLarge])
    .configurationDisplayName("Recent Deployments")
    .description("View the most recent Vercel deployments")
  }
}

struct RecentDeploymentsWidgetView: View {
  var config: RecentDeploymentsEntry
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Recent Deployments")
        .font(.footnote.bold())
      Divider()
      if let deployments = config.deployments {
        ForEach(deployments.prefix(5)) { deployment in
          RecentDeploymentsListRowView(deployment: deployment)
            .font(.caption)
        }
      } else {
        Text("No Deployments Found")
          .font(.caption)
          .fontWeight(.bold)
          .foregroundColor(.secondary)
          .frame(minWidth: 0, maxWidth: .infinity)
      }
      
      Spacer()
      
      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Image(systemName: "person.2.fill")
        Text(config.account.displayString)
      }.font(.caption2).foregroundColor(.secondary).imageScale(.small).lineLimit(1)
    }
    .padding()
    .background(Color.systemBackground)
    .onAppear {
      print(config)
    }
  }
}

struct RecentDeploymentsListRowView: View {
  var deployment: Deployment
  
  var body: some View {
    Label(
      title: {
        VStack {
          Text(deployment.deploymentCause).lineLimit(1)
          HStack {
            Text("\(deployment.project) • \(deployment.date, style: .relative)")
          }
          .font(.caption)
          .foregroundColor(.secondary)
        }
      },
      icon: {
        DeploymentStateIndicator(state: deployment.state, style: .compact)
      }
    )
    .font(.footnote)
    .padding(.vertical, 2)
  }
}
