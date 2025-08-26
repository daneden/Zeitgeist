//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

struct AuthenticatedContentView: View {
	@AppStorage(Preferences.authenticatedAccounts) private var accounts
	
	@State private var signInModel = SignInViewModel()
	@State private var presentSettingsView = false
	@State private var selectedAccount: VercelAccount?

	var body: some View {
		NavigationSplitView {
			List(selection: $selectedAccount) {
				Section {
					ForEach(accounts, id: \.self) {
						AccountListRowView(account: $0)
					}
					.onDelete(perform: deleteAccount)
					
					Button {
						Task { signInModel.signIn() }
					} label: {
						Label("Add Account", systemImage: "plus")
							.backportCircleSymbolVariant()
					}
				} header: {
					Text("Accounts", comment: "Header for accounts list")
				}
			}
#if os(iOS)
			.toolbar {
				ToolbarItem(placement: .navigation) {
					Button {
						presentSettingsView = true
					} label: {
						Label("Settings", systemImage: "ellipsis")
							.backportCircleSymbolVariant()
					}
				}
			}
			.sheet(isPresented: $presentSettingsView) {
				NavigationView {
					SettingsView()
						.navigationBarTitleDisplayMode(.inline)
				}
			}
#endif
			.navigationTitle("Zeitgeist")
		} content: {
			if let selectedAccount {
				NavigationStack {
					ProjectsListView()
						.environmentObject(VercelSession(account: selectedAccount))
						.id(selectedAccount)
				}
			} else {
				Text("No account selected", comment: "Label for projects list when no account is selected")
					.foregroundStyle(.secondary)
			}
		} detail: {
			NavigationStack {
				PlaceholderView(forRole: .ProjectDetail)
			}
		}
		.task(id: accounts.first) {
			selectedAccount = accounts.first
		}
		.onReceive(NotificationCenter.default.publisher(for: .VercelAccountAddedNotification)) { _ in
			selectedAccount = accounts.last
		}
		.onReceive(NotificationCenter.default.publisher(for: .VercelAccountWillBeRemovedNotification), perform: { output in
			guard let index = output.object as? Int else {
				return
			}
			
			let previousAccountIndex = accounts.index(before: index)
			let nextAccountIndex = accounts.index(after: index)
			
			if accounts.indices.contains(previousAccountIndex) {
				selectedAccount = accounts[previousAccountIndex]
			} else if accounts.indices.contains(nextAccountIndex) {
				selectedAccount = accounts[nextAccountIndex]
			} else if accounts.indices.contains(index) {
				selectedAccount = accounts[index]
			} else {
				selectedAccount = nil
			}
		})
	}
	
	func deleteAccount(at indices: IndexSet) {
		for index in indices {
			VercelSession.deleteAccount(id: accounts[index].id)
		}
	}
}

struct AuthenticatedContentView_Previews: PreviewProvider {
	static var previews: some View {
		AuthenticatedContentView()
	}
}
