//
//  View+permissionRevokactionDialog.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 25/08/2022.
//

import SwiftUI

struct PermissionRevocationDialogModifier: ViewModifier {
	@ObservedObject var session: VercelSession
	@State var isVisible = false
	func body(content: Content) -> some View {
		content
			.onAppear {
				isVisible = session.requestsDenied
			}
			.onChange(of: session.requestsDenied) { _ in
				isVisible = session.requestsDenied
			}
			.confirmationDialog(
				"Account permissions revoked",
				isPresented: $isVisible) {
				Button(role: .destructive) {
					VercelSession.deleteAccount(id: session.account.id)
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
