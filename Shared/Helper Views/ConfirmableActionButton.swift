//
//  ConfirmableActionButton.swift
//  Zeitgeist
//
//  Created by Claude on 2026-01-12.
//

import SwiftUI

/// A button that shows a confirmation dialog before executing an action
struct ConfirmableActionButton<Label: View>: View {
	/// The title of the confirmation dialog
	let title: LocalizedStringKey

	/// The message shown in the confirmation dialog
	let message: LocalizedStringKey

	/// The actions available in the confirmation dialog
	let actions: [ConfirmableAction]

	/// Whether the button should be disabled
	var isDisabled: Bool = false

	/// The button's role (e.g., .destructive)
	var buttonRole: ButtonRole? = nil

	/// Whether to use an alert instead of a confirmation dialog (for destructive warnings)
	var useAlert: Bool = false

	/// The button's label
	@ViewBuilder let label: () -> Label

	@State private var isConfirming = false

	var body: some View {
		Button(role: buttonRole) {
			isConfirming = true
		} label: {
			label()
		}
		.disabled(isDisabled)
		.modifier(ConfirmationModifier(
			isPresented: $isConfirming,
			title: title,
			message: message,
			actions: actions,
			useAlert: useAlert
		))
	}
}

/// Represents an action in the confirmation dialog
struct ConfirmableAction: Identifiable {
	let id = UUID()
	let label: LocalizedStringKey
	let role: ButtonRole?
	let action: () async -> Void

	init(_ label: LocalizedStringKey, role: ButtonRole? = nil, action: @escaping () async -> Void) {
		self.label = label
		self.role = role
		self.action = action
	}
}

/// A view modifier that shows either a confirmation dialog or an alert
private struct ConfirmationModifier: ViewModifier {
	@Binding var isPresented: Bool
	let title: LocalizedStringKey
	let message: LocalizedStringKey
	let actions: [ConfirmableAction]
	let useAlert: Bool

	func body(content: Content) -> some View {
		if useAlert {
			content.alert(title, isPresented: $isPresented) {
				ForEach(actions) { action in
					Button(action.label, role: action.role) {
						Task { await action.action() }
					}
				}
				Button("Close", role: .cancel) {
					isPresented = false
				}
			} message: {
				Text(message)
			}
		} else {
			content.confirmationDialog(title, isPresented: $isPresented) {
				Button(role: .cancel) {
					isPresented = false
				} label: {
					Text("Cancel")
				}

				ForEach(actions) { action in
					Button(action.label, role: action.role) {
						Task { await action.action() }
					}
				}
			} message: {
				Text(message)
			}
		}
	}
}

// MARK: - Convenience Initializers

extension ConfirmableActionButton {
	/// Creates a confirmable action button with a single action
	init(
		title: LocalizedStringKey,
		message: LocalizedStringKey,
		confirmLabel: LocalizedStringKey,
		confirmRole: ButtonRole? = nil,
		isDisabled: Bool = false,
		buttonRole: ButtonRole? = nil,
		useAlert: Bool = false,
		action: @escaping () async -> Void,
		@ViewBuilder label: @escaping () -> Label
	) {
		self.title = title
		self.message = message
		self.actions = [ConfirmableAction(confirmLabel, role: confirmRole, action: action)]
		self.isDisabled = isDisabled
		self.buttonRole = buttonRole
		self.useAlert = useAlert
		self.label = label
	}
}
