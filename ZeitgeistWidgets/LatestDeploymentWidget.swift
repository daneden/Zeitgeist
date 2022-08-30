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
		LatestDeploymentEntry(account: WidgetAccount(identifier: nil, display: "No Account"))
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
		if #available(iOSApplicationExtension 16.0, *) {
			return IntentConfiguration(
				kind: kind,
				intent: SelectAccountIntent.self,
				provider: LatestDeploymentProvider()
			) { entry in
				LatestDeploymentWidgetView(config: entry)
			}
			.supportedFamilies([.accessoryRectangular, .systemSmall, .systemMedium])
			.configurationDisplayName("Latest Deployment")
			.description("View the most recent Vercel deployment for an account or project")
		} else {
			return IntentConfiguration(
				kind: kind,
				intent: SelectAccountIntent.self,
				provider: LatestDeploymentProvider()
			) { entry in
				LatestDeploymentWidgetView(config: entry)
			}
			.supportedFamilies([.systemSmall, .systemMedium])
			.configurationDisplayName("Latest Deployment")
			.description("View the most recent Vercel deployment for an account or project")
		}
	}
}

struct LatestDeploymentWidgetView: View {
	@Environment(\.widgetFamily) var widgetFamily
	var config: LatestDeploymentEntry
	
	var hasProject: Bool {
		config.project?.identifier != nil
	}
	
	var isAccessoryView: Bool {
		if #available(iOSApplicationExtension 16.0, *) {
			return widgetFamily == .accessoryRectangular
		} else {
			return false
		}
	}

	var body: some View {
		if isAccessoryView {
			VStack(alignment: .leading) {
				if let deployment = config.deployment {
					HStack {
						DeploymentStateIndicator(state: deployment.state, style: .compact)
						Text(deployment.project)
					}
					Text(deployment.deploymentCause.description)
						.foregroundStyle(.secondary)
					Text(deployment.created, style: .relative)
						.foregroundStyle(.tertiary)
				} else {
					Group {
						HStack {
							DeploymentStateIndicator(state: .queued, style: .compact)
							Text("Loading...")
						}
						Text("Waiting for data")
							.foregroundStyle(.secondary)
						Text(.now, style: .relative)
							.foregroundStyle(.tertiary)
					}.redacted(reason: .placeholder)
				}
			}
		} else {
			Link(destination: URL(string: "zeitgeist://open/\(config.account.identifier ?? "0")/\(config.deployment?.id ?? "0")")!) {
				VStack(alignment: .leading, spacing: 4) {
					if let deployment = config.deployment {
						HStack {
							DeploymentStateIndicator(state: deployment.state)
							Spacer()
							if deployment.target == .production {
								Image(systemName: "theatermasks")
									.foregroundStyle(.tint)
									.symbolVariant(.fill)
									.imageScale(.small)
							}
						}
						.font(.caption.bold())
						.padding(.bottom, 2)
						
						Text(deployment.deploymentCause.description)
							.font(.subheadline)
							.fontWeight(.bold)
							.lineLimit(3)
						
						Text(deployment.created, style: .relative)
							.foregroundStyle(.secondary)
						
						if !hasProject {
							Text(deployment.project)
								.lineLimit(1)
								.foregroundStyle(.secondary)
						}
					} else {
						PlaceholderView(forRole: .NoDeployments, alignment: .leading)
							.font(.footnote)
					}
					
					Spacer()
					
					
					Group {
						WidgetLabel(label: config.account.displayString, iconName: config.account.identifier?.isTeam == true ? "person.2" : "person")
							.symbolVariant(config.account.identifier == nil ? .none : .fill)
						
						if let project = config.project,
							 project.identifier != nil {
							WidgetLabel(label: project.displayString, iconName: "folder")
						}
					}
					.foregroundStyle(.secondary)
					.imageScale(.small)
					.lineLimit(1)
				}
				.multilineTextAlignment(.leading)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.font(.footnote)
			.foregroundStyle(.primary)
			.padding()
			.background(.background)
			.symbolRenderingMode(.hierarchical)
			.tint(.indigo)
		}
	}
}

struct LatestDeploymentWidgetView_Previews: PreviewProvider {
	static var exampleConfig = LatestDeploymentEntry(
		deployment: VercelProject.exampleData.targets!.production!,
		account: WidgetAccount(identifier: "1", display: "Test Account"),
		project: WidgetProject(identifier: "1", display: "example-project")
	)
	static var previews: some View {
		ForEach(DynamicTypeSize.allCases, id: \.self) { typeSize in
			Group {
				LatestDeploymentWidgetView(config: LatestDeploymentEntry(account: WidgetAccount(identifier: nil, display: "No Account")))
					.previewContext(WidgetPreviewContext(family: .systemSmall))
				LatestDeploymentWidgetView(config: exampleConfig)
					.previewContext(WidgetPreviewContext(family: .systemSmall))
				LatestDeploymentWidgetView(config: exampleConfig)
					.previewContext(WidgetPreviewContext(family: .systemMedium))
			}.environment(\.dynamicTypeSize, typeSize)
		}
	}
}
