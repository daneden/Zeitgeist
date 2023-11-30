//
//  SignOutButton.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 30/11/2023.
//

import SwiftUI

struct SignOutButton: View {
	@EnvironmentObject var session: VercelSession
	
	var body: some View {
		Button {
			VercelSession.deleteAccount(id: session.account.id)
		} label: {
			Label("Sign out", systemImage: "person.badge.minus")
		}
	}
}
