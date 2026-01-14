//
//  DeploymentActionsMenu.swift
//  Zeitgeist
//

import SwiftUI

// MARK: - Focused Values

extension FocusedValues {
	@Entry var focusedAccount: VercelAccount?
	@Entry var focusedProject: VercelProject?
	@Entry var focusedDeployment: VercelDeployment?
	@Entry var confirmingDeploymentAction: Binding<DeploymentAction?>?
}

// MARK: - Deployment Action

/// Actions that can be performed on a deployment
enum DeploymentAction: String, CaseIterable, Identifiable {
	case instantRollback
	case promote
	case redeploy
	case redeployWithCache
	case delete
	case cancel

	var id: Self { self }

	// MARK: - UI Metadata

	var label: LocalizedStringKey {
		switch self {
		case .instantRollback: "Instant rollback"
		case .promote: "Promote to production"
		case .redeploy: "Redeploy"
		case .redeployWithCache: "Redeploy with existing build cache"
		case .delete: "Delete deployment"
		case .cancel: "Cancel deployment"
		}
	}

	var systemImage: String {
		switch self {
		case .instantRollback: "clock.arrow.circlepath"
		case .promote: "arrow.up.circle"
		case .redeploy, .redeployWithCache: "arrow.clockwise"
		case .delete: "trash"
		case .cancel: "xmark"
		}
	}

	var keyboardShortcut: KeyboardShortcut? {
		switch self {
		case .instantRollback: KeyboardShortcut("r", modifiers: [.command, .shift, .option])
		case .promote: KeyboardShortcut("p", modifiers: [.command, .shift])
		case .redeploy: KeyboardShortcut("r", modifiers: [.command, .shift])
		case .redeployWithCache: nil
		case .delete: KeyboardShortcut(.delete, modifiers: [.command])
		case .cancel: KeyboardShortcut(".", modifiers: [.command])
		}
	}

	var isDestructive: Bool {
		switch self {
		case .delete, .cancel: true
		default: false
		}
	}

	// MARK: - Availability

	/// Whether this action is available for the given deployment state
	func isAvailable(for deployment: VercelDeployment?, isCurrentProduction: Bool) -> Bool {
		guard let deployment else { return false }
		switch self {
		case .instantRollback:
			return deployment.readySubstate == .promoted && !isCurrentProduction
		case .promote:
			return deployment.state == .ready
		case .redeploy, .redeployWithCache:
			return true
		case .delete:
			return (deployment.state != .queued && deployment.state != .building) || deployment.state == .cancelled
		case .cancel:
			return (deployment.state == .queued || deployment.state == .building) && deployment.state != .cancelled
		}
	}

	/// Whether this action should be shown (vs hidden entirely)
	func shouldShow(for deployment: VercelDeployment?) -> Bool {
		switch self {
		case .delete:
			(deployment?.state != .queued && deployment?.state != .building) || deployment?.state == .cancelled
		case .cancel:
			(deployment?.state == .queued || deployment?.state == .building) && deployment?.state != .cancelled
		default:
			true
		}
	}
}

// MARK: - Shared Menu Content

/// Shared menu content for deployment actions, used by both toolbar menu and macOS commands
struct DeploymentActionMenuContent: View {
	let deployment: VercelDeployment?
	let isCurrentProduction: Bool
	let trigger: (DeploymentAction) -> Void

	var body: some View {
		// Rollback & Promote
		actionButton(.instantRollback)
		actionButton(.promote)

		Divider()

		// Redeploy submenu
		Menu {
			actionButton(.redeploy, showIcon: false)
			actionButton(.redeployWithCache, showIcon: false)
		} label: {
			Label(DeploymentAction.redeploy.label, systemImage: DeploymentAction.redeploy.systemImage)
		}

		Divider()

		// Delete or Cancel
		if DeploymentAction.delete.shouldShow(for: deployment) {
			actionButton(.delete)
		}
		if DeploymentAction.cancel.shouldShow(for: deployment) {
			actionButton(.cancel)
		}
	}

	@ViewBuilder
	private func actionButton(_ action: DeploymentAction, showIcon: Bool = true) -> some View {
		Button(role: action.isDestructive ? .destructive : nil) {
			trigger(action)
		} label: {
			if showIcon {
				Label(action.label, systemImage: action.systemImage)
			} else {
				Text(action.label)
			}
		}
		.disabled(!action.isAvailable(for: deployment, isCurrentProduction: isCurrentProduction))
		.modifier(KeyboardShortcutModifier(shortcut: action.keyboardShortcut))
	}
}

/// Modifier to conditionally apply keyboard shortcut
private struct KeyboardShortcutModifier: ViewModifier {
	let shortcut: KeyboardShortcut?

	func body(content: Content) -> some View {
		if let shortcut {
			content.keyboardShortcut(shortcut)
		} else {
			content
		}
	}
}

// MARK: - Toolbar Menu

/// Toolbar menu for deployment actions
struct DeploymentActionsMenu: View {
	let deployment: VercelDeployment
	let isCurrentProduction: Bool
	let isMutating: Bool
	@Binding var confirmingAction: DeploymentAction?

	var body: some View {
		Menu {
			DeploymentActionMenuContent(
				deployment: deployment,
				isCurrentProduction: isCurrentProduction,
				trigger: { confirmingAction = $0 }
			)
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

// MARK: - macOS Menu Bar Commands

struct DeploymentCommands: Commands {
	@FocusedValue(\.focusedProject) private var project
	@FocusedValue(\.focusedDeployment) private var deployment
	@FocusedValue(\.confirmingDeploymentAction) private var confirmingAction

	private var isCurrentProduction: Bool {
		guard let deployment, let project else { return false }
		return deployment.id == project.targets?.production?.id
	}

	var body: some Commands {
		CommandMenu("Deployment") {
			DeploymentActionMenuContent(
				deployment: deployment,
				isCurrentProduction: isCurrentProduction,
				trigger: { confirmingAction?.wrappedValue = $0 }
			)
			.disabled(deployment == nil)
		}
	}
}

// MARK: - Confirmation Dialogs

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
