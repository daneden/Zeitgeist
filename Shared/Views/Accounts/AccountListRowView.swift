//
//  AccountListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/07/2022.
//

import SwiftUI

struct AccountListRowView: View {
	var account: VercelAccount
	@Environment(AccountManager.self) private var accountManager

	var size: Double {
#if os(macOS)
		20
#else
		24
#endif
	}

	var body: some View {
		Label {
			Text(verbatim: account.name ?? account.username)
		} icon: {
			VercelUserAvatarView(account: account, size: size)
		}
		.contextMenu {
			Button(role: .destructive) {
				accountManager.deleteAccount(id: account.id)
			} label: {
				Label("Sign out", systemImage: "person.badge.minus")
			}
		}
	}
}
