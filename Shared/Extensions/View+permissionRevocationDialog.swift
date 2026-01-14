//
//  View+permissionRevokactionDialog.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 25/08/2022.
//

import SwiftUI

struct PermissionRevocationDialogModifier: ViewModifier {
	@Bindable var session: VercelSession
	@Environment(AccountManager.self) private var accountManager
	@State var isVisible = false

	func body(content: Content) -> some View {
		content
			.onAppear {
				isVisible = session.requestsDenied
			}
			.onChange(of: session.requestsDenied) { _, newValue in
				isVisible = newValue
			}
			.confirmationDialog(
				"Account permissions revoked",
				isPresented: $isVisible) {
				Button(role: .destructive) {
					accountManager.deleteAccount(id: session.account.id)
				} label: {
					Text("Remove account")
				}

				Button(role: .cancel) {
					isVisible = false
				} label: {
					Text("Close")
				}
				} message: {
					Text("There was a problem loading data for this account. It may have been deleted, or its access token may have been revoked.")
				}
	}
}

extension View {
	func permissionRevocationDialog(session: VercelSession) -> some View {
		modifier(PermissionRevocationDialogModifier(session: session))
	}
}

/// Modifier that handles optional session for permission revocation dialog
struct OptionalPermissionRevocationDialogModifier: ViewModifier {
	let session: VercelSession?

	func body(content: Content) -> some View {
		if let session {
			content.permissionRevocationDialog(session: session)
		} else {
			content
		}
	}
}
