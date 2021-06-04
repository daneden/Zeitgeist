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
    return Entry(
      account: WidgetAccount(identifier: nil, display: "Placeholder Account")
    )
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
