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
				Picker(selection: $session.account) {
					ForEach(authenticatedAccounts) { account in
						AccountListRowView(account: account)
							.tag(Optional(account))
							.contextMenu {
								Button(role: .destructive) {
									VercelSession.deleteAccount(id: account.id)
								} label: {
									Label("Delete Account", systemImage: "trash")
								}
							}
					}
					.onDelete(perform: deleteAccount)
					.onMove(perform: move)
				} label: {
					Text("Selected Account")
				}
				.pickerStyle(.inline)
				.toolbar {
					EditButton()
				}
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
			authenticatedAccounts[offset]
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
