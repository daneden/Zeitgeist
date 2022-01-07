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
  var relevance: TimelineEntryRelevance?
}

struct RecentDeploymentsProvider: IntentTimelineProvider {
  typealias Entry = RecentDeploymentsEntry
  func placeholder(in context: Context) -> Entry {
    return Entry(
      account: WidgetAccount(identifier: nil, display: "Placeholder Account")
    )
  }
  
  func getSnapshot(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Entry) -> ()) {
    Task {
      guard let account = configuration.account,
            let accountId = account.identifier else {
              completion(placeholder(in: context))
              return
            }
      
      let loader = DeploymentsViewModel(accountId: accountId)
      
      async let deployments = loader.loadOnce()
      
      let relevance: TimelineEntryRelevance? = await deployments?.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
      
      if let deployments = await deployments {
        completion(Entry(deployments: deployments, account: account, relevance: relevance))
      }
    }
  }
  
  func getTimeline(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
    Task {
      guard let account = configuration.account,
            let accountId = account.identifier else {
              completion(
                Timeline(entries: [placeholder(in: context)], policy: .atEnd)
              )
              return
            }
      
      let loader = DeploymentsViewModel(accountId: accountId)
      
      async let deployments = loader.loadOnce()
      
      let relevance: TimelineEntryRelevance? = await deployments?.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
      
      if let deployments = await deployments {
        completion(
          Timeline (
            entries: [Entry(deployments: deployments, account: account, relevance: relevance)],
            policy: .atEnd
          )
        )
      } else {
        completion(Timeline(entries: [], policy: .atEnd))
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
      HStack {
        Text("Recent Deployments")
          .font(.footnote.bold())
        
        Spacer()
        
        HStack(alignment: .firstTextBaseline, spacing: 2) {
          if config.account.identifier != nil {
            Image(systemName: "person.fill")
            Text(config.account.displayString)
          } else {
            Text("No Account Selected")
          }
        }.font(.caption2).foregroundColor(.secondary).imageScale(.small).lineLimit(1)
      }
      
      if let deployments = config.deployments?.prefix(5) {
        ForEach(deployments) { deployment in
          Spacer()
          Divider()
          Spacer()
          RecentDeploymentsListRowView(accountId: config.account.identifier ?? "0", deployment: deployment)
            .font(.caption)
        }
      } else {
        VStack(alignment: .center) {
          Spacer()
          PlaceholderView(forRole: .NoDeployments)
            .frame(maxWidth: .infinity)
            .font(.footnote)
          Spacer()
        }
      }
      
      Spacer()
    }
    .padding()
    .background(Color.systemBackground)
    .onAppear {
      print(config)
    }
  }
}

struct RecentDeploymentsListRowView: View {
  var accountId: String
  var deployment: Deployment
  
  var body: some View {
    Label(
      title: {
        Link(destination: URL(string: "zeitgeist://open/\(accountId)/\(deployment.id)")!) {
          VStack(alignment: .leading) {
            Text(deployment.deploymentCause)
              .lineLimit(1)
            Text("\(deployment.project) • \(deployment.date, style: .relative)")
              .font(.caption)
              .foregroundColor(.secondary)
          }.frame(maxWidth: .infinity)
        }
      },
      icon: {
        DeploymentStateIndicator(state: deployment.state, style: .compact)
          .fixedSize()
      }
    )
    .font(.footnote)
    .padding(.vertical, 2)
  }
}
