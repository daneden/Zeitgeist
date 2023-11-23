//
//  LatestDeploymentWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI
import WidgetKit

// MARK: - LatestDeploymentProvider

struct LatestDeploymentProvider: IntentTimelineProvider {
	func placeholder(in _: Context) -> LatestDeploymentEntry {
		LatestDeploymentEntry(account: WidgetAccount(identifier: nil, display: "No Account"))
	}

	func getSnapshot(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (LatestDeploymentEntry) -> Void)
	{
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

	func getTimeline(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (Timeline<LatestDeploymentEntry>) -> Void)
	{
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

// MARK: - LatestDeploymentWidget

struct LatestDeploymentWidget: Widget {

	// MARK: Public

	public var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: "LatestDeploymentWidget",
			intent: SelectAccountIntent.self,
			provider: LatestDeploymentProvider()
		) { entry in
			LatestDeploymentWidgetView(config: entry)
		}
		.configurationDisplayName("Latest Deployment")
		.description("View the most recent Vercel deployment for an account or project")
		.supportedFamilies(supportedFamilies)
	}

	// MARK: Private

	private var supportedFamilies: [WidgetFamily] {
		if #available(iOS 16.0, *) {
			[.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular]
		} else {
			[.systemSmall, .systemMedium]
		}
	}

}
