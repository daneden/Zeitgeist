//
//  DeploymentActionsMenu.swift
//  Zeitgeist
//
//  Created by Claude on 2026-01-12.
//

import SwiftUI

// MARK: - Focused Values for macOS Menu Commands
@Observable
final class DeploymentFocusedState {
	var deployment: VercelDeployment?
	var project: VercelProject?
	var isCurrentProduction: Bool = false
	weak var service: DeploymentActionsService?
	var pendingAction: DeploymentAction?

	func triggerAction(_ action: DeploymentAction) {
		pendingAction = action
	}

	func consumeAction() -> DeploymentAction? {
		let action = pendingAction
		pendingAction = nil
		return action
	}
}

extension FocusedValues {
	@Entry var deploymentState: DeploymentFocusedState?
}

/// Actions that can be performed on a deployment, used for confirmation dialogs
enum DeploymentAction: Identifiable {
	case instantRollback
	case promote
	case redeploy
	case redeployWithCache
	case delete
	case cancel

	var id: Self { self }
}

/// A toolbar menu containing all deployment actions
struct DeploymentActionsMenu: View {
	let deployment: VercelDeployment
	let project: VercelProject?
	let isCurrentProduction: Bool
	let isMutating: Bool
	@Binding var confirmingAction: DeploymentAction?

	private var canInstantRollback: Bool {
		deployment.readySubstate == .promoted && !isCurrentProduction
	}

	private var canPromote: Bool {
		deployment.state == .ready
	}

	private var showDeleteButton: Bool {
		(deployment.state != .queued && deployment.state != .building)
			|| deployment.state == .cancelled
	}

	var body: some View {
		Menu {
			Button {
				confirmingAction = .instantRollback
			} label: {
				Label("Instant rollback", systemImage: "clock.arrow.circlepath")
			}
			.disabled(!canInstantRollback)

			Button {
				confirmingAction = .promote
			} label: {
				Label("Promote to production", systemImage: "arrow.up.circle")
			}
			.disabled(!canPromote)

			Divider()

			Menu {
				Button {
					confirmingAction = .redeploy
				} label: {
					Text("Redeploy")
				}

				Button {
					confirmingAction = .redeployWithCache
				} label: {
					Text("Redeploy with existing build cache")
				}
			} label: {
				Label("Redeploy", systemImage: "arrow.clockwise")
			}

			Divider()

			if showDeleteButton {
				Button(role: .destructive) {
					confirmingAction = .delete
				} label: {
					Label("Delete deployment", systemImage: "trash")
				}
			} else {
				Button(role: .destructive) {
					confirmingAction = .cancel
				} label: {
					Label("Cancel deployment", systemImage: "xmark")
				}
			}
		} label: {
			if isMutating {
				ProgressView()
			} else {
				Label("Actions", systemImage: "ellipsis")
			}
		}
		.disabled(isMutating)
	}
}

// MARK: - Confirmation Dialog Modifier

extension View {
	/// Attaches confirmation dialogs for all deployment actions
	func deploymentActionConfirmations(
		confirmingAction: Binding<DeploymentAction?>,
		deployment: VercelDeployment,
		project: VercelProject?,
		isCurrentProduction: Bool,
		service: DeploymentActionsService,
		onDismiss: @escaping () -> Void
	) -> some View {
		self
			.confirmationDialog(
				"Instant rollback",
				isPresented: Binding(
					get: { confirmingAction.wrappedValue == .instantRollback },
					set: { if !$0 { confirmingAction.wrappedValue = nil } }
				)
			) {
				Button("Cancel", role: .cancel) {}
				Button("Restore to production") {
					Task {
						guard let project else { return }
						if await service.instantRollback(deployment, project: project) {
							onDismiss()
						}
					}
				}
			} message: {
				Text("This will restore this deployment to production. Your project's production domains will point to this deployment.")
			}
			.confirmationDialog(
				"Promote to production",
				isPresented: Binding(
					get: { confirmingAction.wrappedValue == .promote },
					set: { if !$0 { confirmingAction.wrappedValue = nil } }
				)
			) {
				Button("Cancel", role: .cancel) {}
				Button("Promote to production") {
					Task {
						let shouldUseStagingPromote = (deployment.target == .staging) || (deployment.target == .production && !isCurrentProduction)
						let success: Bool
						if shouldUseStagingPromote, let project {
							success = await service.promoteStagingToProduction(deployment, project: project)
						} else {
							success = await service.promoteToProduction(deployment)
						}
						if success {
							onDismiss()
						}
					}
				}
			} message: {
				Text("This deployment will be promoted to production. This project's domains will point to your new deployment, and all environment variables defined for the production environment in the project settings will be applied.")
			}
			.confirmationDialog(
				deployment.target == .production ? "Redeploy to production" : "Redeploy",
				isPresented: Binding(
					get: { confirmingAction.wrappedValue == .redeploy },
					set: { if !$0 { confirmingAction.wrappedValue = nil } }
				)
			) {
				Button("Cancel", role: .cancel) {}
				Button("Redeploy") {
					Task {
						if await service.redeploy(deployment) {
							onDismiss()
						}
					}
				}
			} message: {
				Text("You are about to create a new deployment with the same source code as your current deployment, but with the newest configuration from your project settings.")
			}
			.confirmationDialog(
				deployment.target == .production ? "Redeploy to production" : "Redeploy",
				isPresented: Binding(
					get: { confirmingAction.wrappedValue == .redeployWithCache },
					set: { if !$0 { confirmingAction.wrappedValue = nil } }
				)
			) {
				Button("Cancel", role: .cancel) {}
				Button("Redeploy with existing build cache") {
					Task {
						if await service.redeploy(deployment, withCache: true) {
							onDismiss()
						}
					}
				}
			} message: {
				Text("You are about to create a new deployment with the same source code and build cache as your current deployment, but with the newest configuration from your project settings.")
			}
			.alert(
				"Are you sure you want to delete this deployment?",
				isPresented: Binding(
					get: { confirmingAction.wrappedValue == .delete },
					set: { if !$0 { confirmingAction.wrappedValue = nil } }
				)
			) {
				Button("Delete deployment", role: .destructive) {
					Task {
						if await service.deleteDeployment(deployment) {
							#if !os(macOS)
								onDismiss()
							#endif
						}
					}
				}
				Button("Close", role: .cancel) {}
			} message: {
				Text("Deleting this deployment might break links used in integrations, such as the ones in the pull requests of your Git provider. This action cannot be undone.")
			}
			.alert(
				"Are you sure you want to cancel this deployment?",
				isPresented: Binding(
					get: { confirmingAction.wrappedValue == .cancel },
					set: { if !$0 { confirmingAction.wrappedValue = nil } }
				)
			) {
				Button("Cancel deployment", role: .destructive) {
					Task {
						await service.cancelDeployment(deployment)
					}
				}
				Button("Close", role: .cancel) {}
			} message: {
				Text("This will immediately stop the build, with no option to resume.")
			}
	}
}

// MARK: - Menu Bar Commands
struct DeploymentCommands: Commands {
	@FocusedValue(\.deploymentState) var state

	private var deployment: VercelDeployment? {
		state?.deployment
	}

	private var canInstantRollback: Bool {
		guard let state, let deployment = state.deployment else { return false }
		return deployment.readySubstate == .promoted && !state.isCurrentProduction
	}

	private var canPromote: Bool {
		guard let deployment else { return false }
		return deployment.state == .ready
	}

	private var showDeleteButton: Bool {
		guard let deployment else { return false }
		return (deployment.state != .queued && deployment.state != .building)
			|| deployment.state == .cancelled
	}

	var body: some Commands {
		CommandMenu("Deployment") {
			Button("Instant Rollback") {
				state?.triggerAction(.instantRollback)
			}
			.keyboardShortcut("r", modifiers: [.command, .shift, .option])
			.disabled(deployment == nil || !canInstantRollback)
			.onChange(of: state?.deployment) { _, newValue in
				print(state)
			}

			Button("Promote to Production") {
				state?.triggerAction(.promote)
			}
			.keyboardShortcut("p", modifiers: [.command, .shift])
			.disabled(deployment == nil || !canPromote)

			Divider()

			Button("Redeploy") {
				state?.triggerAction(.redeploy)
			}
			.keyboardShortcut("r", modifiers: [.command, .shift])
			.disabled(deployment == nil)

			Button("Redeploy with Build Cache") {
				state?.triggerAction(.redeployWithCache)
			}
			.disabled(deployment == nil)

			Divider()

			if showDeleteButton {
				Button("Delete Deployment") {
					state?.triggerAction(.delete)
				}
				.keyboardShortcut(.delete, modifiers: [.command])
				.disabled(deployment == nil)
			} else {
				Button("Cancel Deployment") {
					state?.triggerAction(.cancel)
				}
				.keyboardShortcut(".", modifiers: [.command])
				.disabled(deployment == nil)
			}
		}
	}
}
