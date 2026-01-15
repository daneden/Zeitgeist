//
//  DeploymentDetailView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

// MARK: - Environment Key for Project

extension EnvironmentValues {
	@Entry var project: VercelProject?
}

// MARK: - Deployment Detail View

struct DeploymentDetailView: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.project) var project
	@Environment(\.session) private var session

	var accountId: VercelAccount.ID? { session?.account.id }
	var deploymentId: VercelDeployment.ID
	@State var deployment: VercelDeployment?
	@State private var actionsService: DeploymentActionsService?
	@State private var confirmingAction: DeploymentAction?

	private var isCurrentProduction: Bool {
		guard let deployment, let project else { return false }
		return deployment.id == project.targets?.production?.id
	}
	
	@State private var showJson = false
	@State private var deploymentData: Data?

	var body: some View {
		Form {
			if let deployment {
				Overview(deployment: deployment)
				Section("Deployment cause") {
					switch deployment.deploymentCause {
					case let .deployHook(name):
						Text("\(Image(deployment.deploymentCause.icon!)) \(name)", comment: "Deploy hook cause icon and name")
					case .promotion(_):
						Text("\(Image(systemName: "arrow.up.circle")) \(deployment.deploymentCause.description)", comment: "Promoted deployment cause icon and name")
						if let meta = deployment.meta, meta.hasCommitInfo {
							CommitSummary(meta: meta)
						}
					case .manual:
						Text("Manual deployment", comment: "Manual deployment cause label")
					case let .gitCommit(meta):
						CommitSummary(meta: meta)
					}
				}
				if let accountId {
					URLDetails(accountId: accountId, deployment: deployment)
				}
				
				#if DEBUG
				Button("View JSON", systemImage: "ellipsis.curlybraces") {
					showJson = true
				}
				.sheet(isPresented: $showJson) {
					NavigationStack {
						ScrollView {
							let json: String? = {
								let encoder = JSONEncoder()
								encoder.outputFormatting = .prettyPrinted
								
								guard let data = try? encoder.encode(deployment) else { return nil }
								
								return String(data: data, encoding: .utf8)
							}()
							
							if let json {
								Text(json)
									.monospaced()
									.textSelection(.enabled)
									.padding()
							}
						}
					}
				}
				#endif
			} else {
				ProgressView()
			}
		}
		.navigationTitle(Text("Deployment details"))
		.toolbar {
			if let deployment, let service = actionsService {
				ToolbarItem(placement: .primaryAction) {
					DeploymentActionsMenu(
						deployment: deployment,
						isCurrentProduction: isCurrentProduction,
						isMutating: service.isMutating,
						confirmingAction: $confirmingAction
					)
				}
			}
		}
		.modifier(DeploymentActionConfirmationsModifier(
			confirmingAction: $confirmingAction,
			deployment: deployment,
			project: project,
			service: actionsService,
			onDismiss: { dismiss() }
		))
		.focusedSceneValue(\.focusedDeployment, deployment)
		.focusedSceneValue(\.confirmingDeploymentAction, $confirmingAction)
		.onAppear {
			if actionsService == nil, let session, let accountId {
				actionsService = DeploymentActionsService(session: session, accountId: accountId)
			}
		}
		.zeitgeistDataTask {
			do {
				try await loadDeploymentDetails()
			} catch {
				print(error.localizedDescription)
			}
		}
	}

	private func loadDeploymentDetails() async throws {
		guard let session, let accountId else { return }
		var request = VercelAPI.request(
			for: .deployments(version: 13, deploymentID: deploymentId),
			with: accountId,
			queryItems: [URLQueryItem(name: "withGitRepoInfo", value: "true")]
		)
		
		try session.signRequest(&request)

		let (data, _) = try await URLSession.shared.data(for: request)
		deploymentData = data
		let decoded = try JSONDecoder().decode(VercelDeployment.self, from: data)
		deployment = decoded
	}
}

/// View modifier wrapper for deployment action confirmations
private struct DeploymentActionConfirmationsModifier: ViewModifier {
	@Binding var confirmingAction: DeploymentAction?
	let deployment: VercelDeployment?
	let project: VercelProject?
	let service: DeploymentActionsService?
	let onDismiss: () -> Void

	private var isCurrentProduction: Bool {
		guard let deployment, let project else { return false }
		return deployment.id == project.targets?.production?.id
	}

	func body(content: Content) -> some View {
		if let deployment, let service {
			content.deploymentActionConfirmations(
				confirmingAction: $confirmingAction,
				deployment: deployment,
				project: project,
				isCurrentProduction: isCurrentProduction,
				service: service,
				onDismiss: onDismiss
			)
		} else {
			content
		}
	}
}

private struct CommitSummary: View {
	var meta: DeploymentMeta

	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Text(meta.commitMessageSummary)
			Spacer()
			if let shortSha = meta.shortSha {
				Text(shortSha)
					.font(.system(.footnote, design: .monospaced))
					.foregroundStyle(.secondary)
			}
		}
		.contextMenu {
			if let sha = meta.commitSha {
				Button {
					Pasteboard.setString(sha)
				} label: {
					Label("Copy commit SHA", systemImage: "doc.on.doc")
				}
			}
		}

		if let commitUrl = meta.commitUrl, let provider = meta.provider {
			Link(destination: commitUrl) {
				Label {
					Text("Open in \(provider.name)")
				} icon: {
					Image(provider.rawValue)
				}
			}
			.contextMenu {
				Button {
					Pasteboard.setString(commitUrl.absoluteString)
				} label: {
					Label("Copy commit URL", systemImage: "doc.on.doc")
				}
			}
		}
	}
}

private struct Overview: View {
	@Environment(\.session) private var session
	var deployment: VercelDeployment

	var body: some View {
		Section("Overview") {
			LabelView(Text("Project")) {
				Text(deployment.project)
			}

			LabelView(Text("Status")) {
				DeploymentStateIndicator(state: deployment.state)
			}

			LabelView(Text("Target")) {
				if deployment.target == .production {
					Label("Production", systemImage: "theatermasks")
						.symbolVariant(.fill)
				} else if deployment.target == .staging {
					Label("Staging", systemImage: "staroflife")
						.symbolVariant(.fill)
				} else {
					Text("Preview")
				}
			}

			LabelView(Text("Build duration")) {
				if let building = deployment.building,
					 let readyAt = deployment.readyAt {
					Text(Duration.seconds(building.distance(to: readyAt)).formatted())
				} else if let building = deployment.building {
					Text(building, style: .timer)
				} else {
					Text("—")
				}
			}

			NavigationLink(value: DetailDestinationValue.deploymentLogs(deployment: deployment)) {
				Label("View logs", systemImage: "terminal")
			}
		}
	}
}

private struct URLDetails: View {
	@Environment(\.session) private var session

	var accountId: VercelAccount.ID
	var deployment: VercelDeployment

	@State private var aliases: [VercelAlias] = []

	var body: some View {
		Section(header: Text("Deployment URL")) {
			Link(destination: deployment.deploymentURL) {
				Label(deployment.deploymentURL.absoluteString, systemImage: "link").lineLimit(1)
			}.keyboardShortcut("o", modifiers: [.command])

			Button {
				Pasteboard.setString(deployment.deploymentURL.absoluteString)
			} label: {
				Label("Copy URL", systemImage: "doc.on.doc")
			}.keyboardShortcut("c", modifiers: [.command])

			DisclosureGroup {
				if aliases.isEmpty {
					Text("No aliases assigned to deployment")
						.foregroundColor(.secondary)
				} else {
					ForEach(aliases, id: \.self) { alias in
						HStack {
							Link(destination: alias.url) {
								Text(alias.url.absoluteString).lineLimit(1)
							}
							Spacer()
						}
					}
				}
			} label: {
				Label("Deployment aliases", systemImage: "arrowshape.turn.up.right")
					.badge(aliases.count)
			}
			.task {
				guard let session else { return }
				do {
					var request = VercelAPI.request(
						for: .deployments(
							version: 5,
							deploymentID: deployment.id,
							path: "aliases"
						),
						with: accountId
					)
					try session.signRequest(&request)
					let (data, _) = try await URLSession.shared.data(for: request)
					try withAnimation {
						aliases = try JSONDecoder().decode(VercelAlias.APIResponse.self, from: data).aliases
					}
				} catch {
					print(error)
				}
			}
		}
	}
}
