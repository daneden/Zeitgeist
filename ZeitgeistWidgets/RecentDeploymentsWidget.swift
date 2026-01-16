//
//  RecentDeploymentstWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import OSLog
import SwiftUI
import WidgetKit

// MARK: - RecentDeploymentsProvider

struct RecentDeploymentsProvider: IntentTimelineProvider {
	private let accountStorage: AccountStorage = UserDefaultsAccountStorage()
	private let networkManager = WidgetNetworkManager.shared

	private static let logger = Logger(
		subsystem: "me.daneden.Zeitgeist.ZeitgeistWidgets",
		category: String(describing: RecentDeploymentsProvider.self)
	)

	/// Refresh interval for successful fetches (15 minutes)
	private static let refreshInterval: TimeInterval = 15 * 60

	/// Refresh interval for failed fetches (5 minutes) - retry sooner on error
	private static let errorRefreshInterval: TimeInterval = 5 * 60

	func placeholder(in _: Context) -> RecentDeploymentsEntry {
		RecentDeploymentsEntry(account: WidgetAccount(identifier: nil, display: "No Account"))
	}

	func getSnapshot(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (RecentDeploymentsEntry) -> Void)
	{
		// For previews, return placeholder immediately
		if context.isPreview {
			completion(placeholder(in: context))
			return
		}

		Task {
			guard let intentAccount = configuration.account,
						let account = accountStorage.loadAccounts().first(where: { $0.id == intentAccount.identifier })
			else {
				Self.logger.debug("No account configured for snapshot")
				completion(placeholder(in: context))
				return
			}

			let productionOnly = configuration.productionOnly?.boolValue ?? false
			let deployments = await networkManager.fetchDeployments(
				account: account,
				projectId: configuration.project?.identifier,
				productionOnly: productionOnly
			)

			if let deployments = deployments {
				let relevance: TimelineEntryRelevance? = deployments.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				completion(
					RecentDeploymentsEntry(
						deployments: deployments,
						account: intentAccount,
						project: configuration.project,
						relevance: relevance,
						productionOnly: productionOnly
					)
				)
			} else {
				Self.logger.warning("Snapshot fetch returned no deployments")
				completion(placeholder(in: context))
			}
		}
	}

	func getTimeline(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (Timeline<RecentDeploymentsEntry>) -> Void)
	{
		Task {
			guard let intentAccount = configuration.account,
						let account = accountStorage.loadAccounts().first(where: { $0.id == intentAccount.identifier })
			else {
				Self.logger.debug("No account configured for timeline")
				completion(
					Timeline(
						entries: [placeholder(in: context)],
						policy: .after(Date().addingTimeInterval(Self.errorRefreshInterval))
					)
				)
				return
			}

			let productionOnly = configuration.productionOnly?.boolValue ?? false
			let deployments = await networkManager.fetchDeployments(
				account: account,
				projectId: configuration.project?.identifier,
				productionOnly: productionOnly
			)

			if let deployments = deployments {
				let relevance: TimelineEntryRelevance? = deployments.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				Self.logger.debug("Timeline updated with \(deployments.count) deployments")
				completion(
					Timeline(
						entries: [
							RecentDeploymentsEntry(
								deployments: deployments,
								account: intentAccount,
								project: configuration.project,
								relevance: relevance,
								productionOnly: productionOnly
							)
						],
						policy: .after(Date().addingTimeInterval(Self.refreshInterval))
					)
				)
			} else {
				// Always call completion, even when fetch fails
				Self.logger.warning("Timeline fetch failed, scheduling retry")
				completion(
					Timeline(
						entries: [placeholder(in: context)],
						policy: .after(Date().addingTimeInterval(Self.errorRefreshInterval))
					)
				)
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
