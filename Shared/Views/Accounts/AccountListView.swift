//
//  AccountListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct AccountListView: View {
	@AppStorage(Preferences.authenticatedAccounts)
	var authenticatedAccounts

	@EnvironmentObject var session: VercelSession
	@State var signInModel = SignInViewModel()

	var body: some View {
		List {
			Section {
				ForEach(authenticatedAccounts, id: \.self) { account in
					Button {
						withAnimation(.interactiveSpring()) { session.account = account }
					} label: {
						HStack {
							AccountListRowView(account: account)

							if account == session.account {
								Spacer()
								Image(systemName: "checkmark")
									.foregroundStyle(.primary)
							}
						}
					}
					.foregroundStyle(.primary)
					.contextMenu {
						Button(role: .destructive) {
							VercelSession.deleteAccount(id: account.id)
						} label: {
							Label("Delete Account", systemImage: "person.badge.minus")
						}
					}
				}
				.onDelete(perform: deleteAccount)
				.onMove(perform: move)
			}

			Section {
				Button(action: { signInModel.signIn() }) {
					Label("Add New Account", systemImage: "person.badge.plus")
				}
			}
		}
	}

	func deleteAccount(at offsets: IndexSet) {
		let accounts = offsets.map { offset in
			Preferences.accounts[offset]
		}

		for account in accounts {
			VercelSession.deleteAccount(id: account.id)
		}
	}

	func move(from source: IndexSet, to destination: Int) {
		Preferences.accounts.move(fromOffsets: source, toOffset: destination)
	}
}

struct AccountListView_Previews: PreviewProvider {
	static var previews: some View {
		AccountListView()
	}
}
