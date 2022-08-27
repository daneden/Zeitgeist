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
		.supportedFamilies([.systemSmall, .systemMedium])
		.configurationDisplayName("Latest Deployment")
		.description("View the most recent Vercel deployment")
	}
}

struct LatestDeploymentWidgetView: View {
	var config: LatestDeploymentEntry
	
	var hasProject: Bool {
		config.project?.identifier != nil
	}

	var body: some View {
		Link(destination: URL(string: "zeitgeist://open/\(config.account.identifier ?? "0")/\(config.deployment?.id ?? "0")")!) {
			VStack(alignment: .leading, spacing: 4) {
				if let deployment = config.deployment {
					DeploymentStateIndicator(state: deployment.state)
						.font(Font.caption.bold())
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
					Label {
						Text(config.account.displayString)
					} icon: {
						Image(systemName: config.account.identifier?.isTeam == true ? "person.2" : "person")
							.symbolVariant(config.account.identifier == nil ? .none : .fill)
					}
					
					if let project = config.project,
						 project.identifier != nil {
						Text("\(Image(systemName: "folder")) \(project.displayString)")
							.fontWeight(.medium)
							.padding(2)
							.padding(.horizontal, 2)
							.background(.thickMaterial)
							.clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
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
