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
			account: WidgetAccount(identifier: nil, display: "No Account")
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
		.supportedFamilies([.systemLarge, .systemExtraLarge])
		.configurationDisplayName("Recent Deployments")
		.description("View a list of the most recent Vercel deployments for an account or project")
	}
}

struct RecentDeploymentsWidgetView: View {
	@Environment(\.sizeCategory) var sizeCategory
	var config: RecentDeploymentsEntry
	
	var accountLabel: some View {
		Label {
			Text(config.account.displayString)
		} icon: {
			Image(systemName: "person")
				.symbolVariant(config.account.identifier == nil ? .none : .fill)
		}
		.foregroundStyle(.secondary)
	}
	
	var widgetTitle: some View {
		Label("Recent Deployments", systemImage: "clock")
			.font(.footnote.bold())
	}
	
	var numberOfDeployments: Int {
		switch sizeCategory {
		case .extraSmall,
				.small,
				.medium,
				.large:
			return 5
		case .accessibilityExtraLarge,
				.accessibilityExtraExtraLarge,
				.accessibilityExtraExtraExtraLarge:
			return 3
		default: return 4
		}
	}

	var body: some View {
		VStack(alignment: .leading) {
			widgetTitle

			if let deployments = config.deployments?.prefix(numberOfDeployments) {
				ForEach(deployments) { deployment in
					Divider()
					Spacer(minLength: 0)
					RecentDeploymentsListRowView(
						accountId: config.account.identifier ?? "0",
						deployment: deployment,
						project: config.project
					)
					Spacer(minLength: 0)
				}
			} else {
				VStack(alignment: .center) {
					Spacer(minLength: 0)
					PlaceholderView(forRole: .NoDeployments)
						.frame(maxWidth: .infinity)
						.font(.footnote)
					Spacer(minLength: 0)
				}
			}

			Spacer(minLength: 0)
			
			HStack {
				WidgetLabel(label: config.account.displayString, iconName: config.account.identifier?.isTeam == true ? "person.2" : "person")
					.symbolVariant(config.account.identifier == nil ? .none : .fill)
				
				Spacer()
				
				if let project = config.project,
					 project.identifier != nil {
					WidgetLabel(label: project.displayString, iconName: "folder")
				}
			}
			.font(.caption)
			.foregroundStyle(.secondary)
			.lineLimit(1)
		}
		.padding()
		.background(.background)
	}
}

struct RecentDeploymentsListRowView: View {
	@Environment(\.dynamicTypeSize) var dynamicTypeSize
	var accountId: String
	var deployment: VercelDeployment
	var project: WidgetProject?

	var body: some View {
		Link(destination: URL(string: "zeitgeist://open/\(accountId)/\(deployment.id)")!) {
			Label {
				VStack(alignment: .leading) {
					Text(deployment.deploymentCause.description)
						.fontWeight(.bold)
						.foregroundStyle(.primary)
					
					HStack {
						if deployment.target == .production {
							Image(systemName: "theatermasks")
								.foregroundStyle(.tint)
								.symbolRenderingMode(.hierarchical)
								.symbolVariant(.fill)
								.imageScale(.small)
						}
						
						if project?.identifier == nil {
							HStack {
								Text(deployment.project)
								Text(verbatim: "•")
								Text(deployment.created, style: .relative)
							}
						} else {
							Text(deployment.created, style: .relative)
						}
					}
				}
				.foregroundStyle(.secondary)
				.lineLimit(1)
				.imageScale(dynamicTypeSize.isAccessibilitySize ? .small : .medium)
			} icon: {
				DeploymentStateIndicator(state: deployment.state, style: .compact)
			}
			.font(.subheadline)
			.tint(.indigo)
		}
	}
}

struct RecentDeploymentsWidgetView_Previews: PreviewProvider {
	static var exampleConfig = RecentDeploymentsEntry(
		deployments: Array(repeating: VercelProject.exampleData.targets!.production!, count: 12),
		account: WidgetAccount(identifier: "1", display: "Test Account"),
		project: WidgetProject(identifier: "1", display: "example-project")
	)
	static var previews: some View {
		ForEach(DynamicTypeSize.allCases, id: \.self) { typeSize in
			Group {
				RecentDeploymentsWidgetView(config: exampleConfig)
					.previewContext(WidgetPreviewContext(family: .systemLarge))
			}.environment(\.dynamicTypeSize, typeSize)
		}
	}
}
