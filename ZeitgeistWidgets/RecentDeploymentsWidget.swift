//
//  RecentDeploymentstWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI
import WidgetKit

// MARK: - RecentDeploymentsProvider

struct RecentDeploymentsProvider: IntentTimelineProvider {
	private let accountStorage: AccountStorage = UserDefaultsAccountStorage()

	func placeholder(in _: Context) -> RecentDeploymentsEntry {
		RecentDeploymentsEntry(account: WidgetAccount(identifier: nil, display: "No Account"))
	}

	func getSnapshot(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (RecentDeploymentsEntry) -> Void)
	{
		Task { @MainActor in
			guard let intentAccount = configuration.account,
						let account = accountStorage.loadAccounts().first(where: { $0.id == intentAccount.identifier }),
						let session = VercelSession(account: account)
			else {
				completion(placeholder(in: context))
				return
			}

			do {
				var queryItems: [URLQueryItem] = []

				if let projectId = configuration.project?.identifier {
					queryItems.append(URLQueryItem(name: "projectId", value: projectId))
				}

				let productionOnly = configuration.productionOnly?.boolValue ?? false

				if productionOnly {
					queryItems.append(URLQueryItem(name: "target", value: "production"))
				}

				var request = VercelAPI.request(for: .deployments(), with: account.id, queryItems: queryItems)
				try session.signRequest(&request)
				let (data, _) = try await URLSession.shared.data(for: request)
				let deployments = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data).deployments

				let relevance: TimelineEntryRelevance? = deployments.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				completion(RecentDeploymentsEntry(deployments: deployments, account: intentAccount, project: configuration.project, relevance: relevance, productionOnly: productionOnly))
			} catch {
				print(error)
			}
		}
	}

	func getTimeline(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (Timeline<RecentDeploymentsEntry>) -> Void)
	{
		Task { @MainActor in
			guard let intentAccount = configuration.account,
						let account = accountStorage.loadAccounts().first(where: { $0.id == intentAccount.identifier }),
						let session = VercelSession(account: account)
			else {
				completion(
					Timeline(entries: [placeholder(in: context)], policy: .atEnd)
				)
				return
			}

			do {
				var queryItems: [URLQueryItem] = []

				if let projectId = configuration.project?.identifier {
					queryItems.append(URLQueryItem(name: "projectId", value: projectId))
				}

				if configuration.productionOnly?.boolValue == true {
					queryItems.append(URLQueryItem(name: "target", value: "production"))
				}

				var request = VercelAPI.request(for: .deployments(), with: account.id, queryItems: queryItems)
				try session.signRequest(&request)
				let (data, _) = try await URLSession.shared.data(for: request)
				let deployments = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data).deployments

				let relevance: TimelineEntryRelevance? = deployments.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				completion(
					Timeline(
						entries: [RecentDeploymentsEntry(deployments: deployments, account: intentAccount, project: configuration.project, relevance: relevance)],
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

// MARK: - RecentDeploymentsWidget

struct RecentDeploymentsWidget: Widget {
	public var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: "RecentDeploymentsWidget",
			intent: SelectAccountIntent.self,
			provider: RecentDeploymentsProvider()
		) { entry in
			RecentDeploymentsWidgetView(config: entry)
				.containerBackground(.background, for: .widget)
		}
		.configurationDisplayName("Recent Deployments")
		.description("View a list of the most recent Vercel deployments for an account or project")
		.supportedFamilies([.systemLarge, .systemExtraLarge])
	}
}

@available(iOS 26, macOS 26, *)
struct RecentDeploymentsWidgetWithPushHandler: Widget {
	public var body: some WidgetConfiguration {
		RecentDeploymentsWidget()
			.body
			.pushHandler(ZeitgeistWidgetPushHandler.self)
	}
}
