//
//  SignOutButton.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 30/11/2023.
//

import SwiftUI

struct SignOutButton: View {
	@Environment(\.session) private var session

	var body: some View {
		Button {
			#if !EXTENSION
			if let session {
				VercelSession.deleteAccount(id: session.account.id)
			}
			#endif
		} label: {
			Label("Sign out", systemImage: "person.badge.minus")
		}
	}
}
