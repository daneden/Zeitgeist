//
//  DeploymentDetailView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

extension EnvironmentValues {
	@Entry var project: VercelProject?
}

struct DeploymentDetailView: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.project) var project: VercelProject?
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID { session.account.id }
	var deploymentId: VercelDeployment.ID
	@State var deployment: VercelDeployment?
	@State private var actionsService: DeploymentActionsService?
	@State private var confirmingAction: DeploymentAction?
	@State private var focusedState = AppFocusedState()

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
						if let commit = deployment.commit {
							CommitSummary(commit: commit)
						}
					case .manual:
						Text("Manual deployment", comment: "Manual deployment cause label")
					case let .gitCommit(commit):
						CommitSummary(commit: commit)
					}
				}
				URLDetails(accountId: accountId, deployment: deployment)
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
						isCurrentProduction: focusedState.isCurrentProduction,
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
		.focusedSceneValue(\.appState, focusedState)
		.onAppear {
			if actionsService == nil {
				actionsService = DeploymentActionsService(session: session, accountId: accountId)
			}
		}
		.task(id: deployment) {
			focusedState.deployment = deployment
		}
		.task(id: project) {
			focusedState.project = project
		}
		.onChange(of: actionsService?.id) { _, _ in
			if let actionsService {
				focusedState.deploymentActionsService = actionsService
			}
		}
		.onChange(of: focusedState.pendingDeploymentAction) { _, newValue in
			if let action = newValue {
				confirmingAction = action
				focusedState.pendingDeploymentAction = nil
			}
		}
		.zeitgeistDataTask {
			do {
				try await loadDeploymentDetails()
			} catch {
				print(error)
			}
		}
	}

	private func loadDeploymentDetails() async throws {
		var request = VercelAPI.request(for: .deployments(version: 13, deploymentID: deploymentId), with: accountId)
		try session.signRequest(&request)

		let (data, _) = try await URLSession.shared.data(for: request)
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
	var commit: AnyCommit
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			Text(commit.commitMessageSummary)
			Spacer()
			Text(commit.shortSha)
				.font(.system(.footnote, design: .monospaced))
				.foregroundStyle(.secondary)
		}
		.contextMenu {
			Button {
				Pasteboard.setString(commit.commitSha)
			} label: {
				Label("Copy commit SHA", systemImage: "doc.on.doc")
			}
		}
		
		Link(destination: commit.commitUrl) {
			Label {
				Text("Open in \(commit.provider.name)")
			} icon: {
				Image(commit.provider.rawValue)
			}
		}
		.contextMenu {
			Button {
				Pasteboard.setString(commit.commitUrl.absoluteString)
			} label: {
				Label("Copy commit URL", systemImage: "doc.on.doc")
			}
		}
	}
}

private struct Overview: View {
	@EnvironmentObject var session: VercelSession
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
			
			NavigationLink {
				DeploymentLogView(deployment: deployment)
					.environmentObject(session)
			} label: {
				Label("View logs", systemImage: "terminal")
			}
		}
	}
}

private struct URLDetails: View {
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID
	var deployment: VercelDeployment

	@State private var aliases: [VercelAlias] = []

	var body: some View {
		Section(header: Text("Deployment URL")) {
			Link(destination: deployment.url) {
				Label(deployment.url.absoluteString, systemImage: "link").lineLimit(1)
			}.keyboardShortcut("o", modifiers: [.command])

			Button {
				Pasteboard.setString(deployment.url.absoluteString)
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

