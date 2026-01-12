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
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID { session.account.id }
	var deploymentId: VercelDeployment.ID
	@State var deployment: VercelDeployment?
	@State var isCurrentProduction = false

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
				DeploymentDetails(accountId: accountId, deployment: deployment, isCurrentProduction: isCurrentProduction)
			} else {
				ProgressView()
			}
		}
		.navigationTitle(Text("Deployment details"))
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

private struct DeploymentDetails: View {
	@Environment(\.dismiss) var dismiss
	@Environment(\.project) var project: VercelProject?
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID
	var deployment: VercelDeployment
	var isCurrentProduction: Bool

	@State private var actionsService: DeploymentActionsService?

	private var service: DeploymentActionsService {
		actionsService ?? DeploymentActionsService(session: session, accountId: accountId)
	}

	private var showDeleteButton: Bool {
		(deployment.state != .queued && deployment.state != .building)
			|| deployment.state == .cancelled
			|| service.recentlyCancelled
	}

	private var shouldUseStagingPromote: Bool {
		(deployment.target == .staging) || (deployment.target == .production && !isCurrentProduction)
	}

	var body: some View {
		Section("Details") {
			NavigationLink {
				DeploymentLogView(deployment: deployment)
					.environmentObject(session)
			} label: {
				Label("View logs", systemImage: "terminal")
			}

			Group {
				// Instant rollback for production deployments
				ConfirmableActionButton(
					title: "Instant rollback",
					message: "This will restore this deployment to production. Your project's production domains will point to this deployment.",
					confirmLabel: "Restore to production",
					isDisabled: deployment.readySubstate != .promoted || isCurrentProduction
				) {
					guard let project else { return }
					if await service.instantRollback(deployment, project: project) {
						dismiss()
					}
				} label: {
					Label("Instant rollback", systemImage: "clock.arrow.circlepath")
				}

				// Promote to production
				ConfirmableActionButton(
					title: "Promote to production",
					message: "This deployment will be promoted to production. This project's domains will point to your new deployment, and all environment variables defined for the production environment in the project settings will be applied.",
					confirmLabel: "Promote to production",
					isDisabled: deployment.state != .ready
				) {
					let success: Bool
					if shouldUseStagingPromote, let project {
						success = await service.promoteStagingToProduction(deployment, project: project)
					} else {
						success = await service.promoteToProduction(deployment)
					}
					if success {
						dismiss()
					}
				} label: {
					Label("Promote to production", systemImage: "arrow.up.circle")
				}

				// Redeploy (with multiple options)
				ConfirmableActionButton(
					title: deployment.target == .production ? "Redeploy to production" : "Redeploy",
					message: "You are about to create a new deployment with the same source code as your current deployment, but with the newest configuration from your project settings.",
					actions: [
						ConfirmableAction("Redeploy") {
							if await service.redeploy(deployment) {
								dismiss()
							}
						},
						ConfirmableAction("Redeploy with existing build cache") {
							if await service.redeploy(deployment, withCache: true) {
								dismiss()
							}
						}
					]
				) {
					Label("Redeploy", systemImage: "arrow.clockwise")
				}

				// Delete or Cancel deployment
				if showDeleteButton {
					ConfirmableActionButton(
						title: "Are you sure you want to delete this deployment?",
						message: "Deleting this deployment might break links used in integrations, such as the ones in the pull requests of your Git provider. This action cannot be undone.",
						confirmLabel: "Delete deployment",
						confirmRole: .destructive,
						buttonRole: .destructive,
						useAlert: true
					) {
						if await service.deleteDeployment(deployment) {
							#if !os(macOS)
								dismiss()
							#endif
						}
					} label: {
						Label("Delete deployment", systemImage: "trash")
					}
					.symbolRenderingMode(.multicolor)
				} else {
					ConfirmableActionButton(
						title: "Are you sure you want to cancel this deployment?",
						message: "This will immediately stop the build, with no option to resume.",
						confirmLabel: "Cancel deployment",
						confirmRole: .destructive,
						buttonRole: .destructive,
						useAlert: true
					) {
						await service.cancelDeployment(deployment)
					} label: {
						HStack {
							Label("Cancel deployment", systemImage: "xmark")

							if service.isMutating {
								Spacer()
								ProgressView()
							}
						}
					}
					.symbolRenderingMode(.multicolor)
				}
			}
			.disabled(service.isMutating)
		}
		.onAppear {
			if actionsService == nil {
				actionsService = DeploymentActionsService(session: session, accountId: accountId)
			}
		}
	}
}

