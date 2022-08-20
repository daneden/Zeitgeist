//
//  LatestDeploymentWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI
import WidgetKit

struct LatestDeploymentEntry: TimelineEntry {
	var date = Date()
	var deployment: VercelDeployment?
	var account: WidgetAccount
	var project: WidgetProject?
	var relevance: TimelineEntryRelevance?
}

struct LatestDeploymentProvider: IntentTimelineProvider {
	typealias Entry = LatestDeploymentEntry
	func placeholder(in _: Context) -> LatestDeploymentEntry {
		LatestDeploymentEntry(account: WidgetAccount(identifier: nil, display: "Placeholder Account"))
	}

	func getSnapshot(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (LatestDeploymentEntry) -> Void) {
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
				if let deployment = deployments.first {
					completion(
						LatestDeploymentEntry(
							deployment: deployment,
							account: intentAccount,
							project: configuration.project,
							relevance: relevance
						)
					)
				}
			} catch {
				print(error)
			}
		}
	}

	func getTimeline(for configuration: SelectAccountIntent, in context: Context, completion: @escaping (Timeline<LatestDeploymentEntry>) -> Void) {
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
				if let deployment = deployments.first {
					completion(
						Timeline(entries: [
							LatestDeploymentEntry(
								deployment: deployment,
								account: intentAccount,
								project: configuration.project,
								relevance: relevance
							),
						], policy: .atEnd)
					)
				} else {
					completion(Timeline(entries: [], policy: .atEnd))
				}
			} catch {
				print(error)
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

					Text(deployment.deploymentCause.description)
						.font(.subheadline)
						.fontWeight(.bold)
						.lineLimit(3)
						.foregroundColor(.primary)

					Text(deployment.created, style: .relative)
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
		.background(.background)
	}
}
