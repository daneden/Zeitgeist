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
	private let accountStorage: AccountStorage = UserDefaultsAccountStorage()

	func placeholder(in _: Context) -> LatestDeploymentEntry {
		LatestDeploymentEntry(account: WidgetAccount(identifier: nil, display: "No Account"))
	}

	func getSnapshot(
		for configuration: SelectAccountIntent,
		in context: Context,
		completion: @escaping (LatestDeploymentEntry) -> Void)
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

				if configuration.productionOnly?.boolValue == true {
					queryItems.append(URLQueryItem(name: "target", value: "production"))
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
				if let deployment = deployments.first {
					completion(
						Timeline(entries: [
							LatestDeploymentEntry(
								deployment: deployment,
								account: intentAccount,
								project: configuration.project,
								relevance: relevance
							),
						], policy: .never)
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
