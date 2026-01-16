//
//  LatestDeploymentWidget.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import OSLog
import SwiftUI
import WidgetKit

// MARK: - LatestDeploymentProvider

struct LatestDeploymentProvider: IntentTimelineProvider {
	private let accountStorage: AccountStorage = UserDefaultsAccountStorage()
	private let networkManager = WidgetNetworkManager.shared

	private static let logger = Logger(
		subsystem: "me.daneden.Zeitgeist.ZeitgeistWidgets",
		category: String(describing: LatestDeploymentProvider.self)
	)

	/// Refresh interval for successful fetches (60 minutes)
	/// This is an infrequent update since most updates will come from the backend server
	private static let refreshInterval: TimeInterval = 60 * 60

	/// Refresh interval for failed fetches (15 minutes) - retry sooner on error
	private static let errorRefreshInterval: TimeInterval = 15 * 60

	func placeholder(in _: Context) -> LatestDeploymentEntry {
		LatestDeploymentEntry(account: WidgetAccount(identifier: nil, display: "No Account"))
	}

	func getSnapshot(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (LatestDeploymentEntry) -> Void)
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

			if let deployment = deployments?.first {
				let relevance: TimelineEntryRelevance? = deployments?.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				completion(
					LatestDeploymentEntry(
						deployment: deployment,
						account: intentAccount,
						project: configuration.project,
						relevance: relevance
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
		completion: @escaping (Timeline<LatestDeploymentEntry>) -> Void)
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

			if let deployment = deployments?.first {
				let relevance: TimelineEntryRelevance? = deployments?.prefix(2).first(where: { $0.state == .error }) != nil ? .init(score: 10) : nil
				Self.logger.debug("Timeline updated with deployment: \(deployment.id)")
				completion(
					Timeline(
						entries: [
							LatestDeploymentEntry(
								deployment: deployment,
								account: intentAccount,
								project: configuration.project,
								relevance: relevance
							),
						],
						policy: .after(Date().addingTimeInterval(Self.refreshInterval))
					)
				)
			} else {
				// Always call completion, even when no deployments found
				Self.logger.warning("Timeline fetch returned no deployments, scheduling retry")
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

// MARK: - LatestDeploymentWidget
struct LatestDeploymentWidget: Widget {
	public var body: some WidgetConfiguration {
		IntentConfiguration(
			kind: "LatestDeploymentWidget",
			intent: SelectAccountIntent.self,
			provider: LatestDeploymentProvider()
		) { entry in
			LatestDeploymentWidgetView(config: entry)
				.containerBackground(.background, for: .widget)
		}
		.configurationDisplayName("Latest Deployment")
		.description("View the most recent Vercel deployment for an account or project")
		.supportedFamilies(supportedFamilies)
	}

	private var supportedFamilies: [WidgetFamily] {
		if #available(iOSApplicationExtension 16.0, *) {
			[.systemSmall, .systemMedium, .accessoryRectangular, .accessoryCircular]
		} else {
			[.systemSmall, .systemMedium]
		}
	}
}

@available(iOS 26, macOS 26, *)
struct LatestDeploymentWidgetWithPushHandler: Widget {
	public var body: some WidgetConfiguration {
		LatestDeploymentWidget()
			.body
			.pushHandler(ZeitgeistWidgetPushHandler.self)
	}
}
