//
//  RecentDeploymentstWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI
import WidgetKit

struct RecentDeploymentsEntry: TimelineEntry {
	var date = Date()
	var deployments: [VercelDeployment]?
	var account: WidgetAccount
	var project: WidgetProject?
	var relevance: TimelineEntryRelevance?
}

struct RecentDeploymentsProvider: IntentTimelineProvider {
	typealias Entry = RecentDeploymentsEntry
	func placeholder(in _: Context) -> Entry {
		return Entry(
			account: WidgetAccount(identifier: nil, display: "Placeholder Account")
		)
	}

	func getSnapshot(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Entry) -> Void) {
		Task {
			guard let intentAccount = configuration.account,
						let account = Preferences.accounts.first(where: { $0.id == intentAccount.identifier })
			else {
				completion(placeholder(in: context))
				return
			}

			do {
				let session = VercelSession(account: account)
				var queryItems: [URLQueryItem] = []
				
				if let projectId = configuration.project?.identifier {
					queryItems.append(URLQueryItem(name: "projectId", value: projectId))
				}
				
				var request = VercelAPI.request(for: .deployments(), with: account.id, queryItems: queryItems)
				try session.signRequest(&request)
				let (data, _) = try await URLSession.shared.data(for: request)
				let deployments = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data).deployments

				let relevance: TimelineEntryRelevance? = deployments.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				completion(Entry(deployments: deployments, account: intentAccount, project: configuration.project, relevance: relevance))
			} catch {
				print(error)
			}
		}
	}

	func getTimeline(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
		Task {
			guard let intentAccount = configuration.account,
						let account = Preferences.accounts.first(where: { $0.id == intentAccount.identifier })
			else {
				completion(
					Timeline(entries: [placeholder(in: context)], policy: .atEnd)
				)
				return
			}
			
			do {
				let session = VercelSession(account: account)
				var queryItems: [URLQueryItem] = []
				
				if let projectId = configuration.project?.identifier {
					queryItems.append(URLQueryItem(name: "projectId", value: projectId))
				}
				
				var request = VercelAPI.request(for: .deployments(), with: account.id, queryItems: queryItems)
				try session.signRequest(&request)
				let (data, _) = try await URLSession.shared.data(for: request)
				let deployments = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data).deployments

				let relevance: TimelineEntryRelevance? = deployments.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				completion(
					Timeline(
						entries: [Entry(deployments: deployments, account: intentAccount, project: configuration.project, relevance: relevance)],
						policy: .atEnd
					)
				)
			} catch {
				print(error)
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
	@Environment(\.sizeCategory) var sizeCategory
	var config: RecentDeploymentsEntry
	
	var accountLabel: some View {
			Group {
			if config.account.identifier != nil {
				Label(config.account.displayString, systemImage: "person")
			} else {
				Text("No Account Selected")
			}
		}
		.foregroundStyle(.secondary)
		.symbolVariant(.fill)
	}
	
	var topLabel: some View {
		Group {
			if let projectName = config.project?.displayString,
				 config.project?.identifier != nil {
				VStack(alignment: .leading) {
					widgetTitle
					HStack {
						accountLabel
						Spacer()
						Label(projectName, systemImage: "folder")
							.foregroundStyle(.secondary)
							.symbolVariant(.fill)
					}
				}
			} else {
				HStack(alignment: .firstTextBaseline) {
					widgetTitle
					Spacer()
					accountLabel
				}
			}
		}
		.font(.footnote)
	}
	
	var widgetTitle: some View {
		Label("Recent Deployments", systemImage: "clock")
			.font(.footnote.bold())
	}
	
	var numberOfDeployments = 4

	var body: some View {
		VStack(alignment: .leading) {
			topLabel

			if let deployments = config.deployments?.prefix(numberOfDeployments) {
				ForEach(deployments) { deployment in
					Divider()
					RecentDeploymentsListRowView(
						accountId: config.account.identifier ?? "0",
						deployment: deployment,
						project: config.project
					)
						.frame(maxHeight: .infinity)
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
		.background(.background)
	}
}

struct RecentDeploymentsListRowView: View {
	var accountId: String
	var deployment: VercelDeployment
	var project: WidgetProject?

	var body: some View {
		Link(destination: URL(string: "zeitgeist://open/\(accountId)/\(deployment.id)")!) {
			Label {
				VStack(alignment: .leading) {
					Text(deployment.deploymentCause.description)
						.font(.subheadline.bold())
					
					Group {
						if project?.identifier == nil {
							Text("\(deployment.project) • \(deployment.created, style: .relative)")
						} else {
							Text("\(deployment.created, style: .relative)")
						}
					}
					.font(.subheadline)
					.foregroundStyle(.secondary)
					
					if let message = deployment.commit?.commitMessage.split(separator: "\n").dropFirst().joined(separator: "\n") {
						Text(message)
							.font(.subheadline)
							.foregroundStyle(.secondary)
					}
				}
				.lineLimit(1)
				.frame(maxWidth: .infinity)
			} icon: {
				DeploymentStateIndicator(state: deployment.state, style: .compact)
			}
		}
	}
}
