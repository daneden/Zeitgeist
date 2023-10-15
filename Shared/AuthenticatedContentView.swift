//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

fileprivate struct AccountListRow: View {
	var account: VercelAccount
	
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
	}
}

struct AuthenticatedContentView: View {
	@AppStorage(Preferences.authenticatedAccounts) private var accounts
	
	@State private var signInModel = SignInViewModel()
	@State private var presentSettingsView = false
	@State private var selectedAccount: VercelAccount?
	
	#if os(iOS)
	@ToolbarContentBuilder
	var toolbarContent: some ToolbarContent {
		ToolbarItem(placement: .navigation) {
			Button {
				presentSettingsView = true
			} label: {
				Label("More", systemImage: "ellipsis.circle")
			}
			.sheet(isPresented: $presentSettingsView) {
				NavigationView {
					SettingsView()
						.navigationBarTitleDisplayMode(.inline)
				}
			}
		}
	}
	#endif

	var body: some View {
		Group {
			if #available(iOS 16.0, macOS 13.0, *) {
				NavigationSplitView {
					List(selection: $selectedAccount) {
						Section {
							ForEach(accounts, id: \.self) {
								AccountListRow(account: $0)
							}
							.onDelete(perform: deleteAccount)
							
							Button {
								Task { signInModel.signIn() }
							} label: {
								Label("Add Account", systemImage: "plus.circle")
							}
						} header: {
							Text("Accounts", comment: "Header for accounts list")
						}
					}
#if os(iOS)
					.toolbar {
						toolbarContent
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
			} else {
				NavigationView {
					List {
						ForEach(accounts) { account in
							let session = VercelSession(account: account)
							
							NavigationLink {
								ProjectsListView()
									.environmentObject(session)
							} label: {
								AccountListRow(account: account)
							}
						}
					}
					.navigationTitle("Zeitgeist")
#if os(iOS)
					.toolbar {
						toolbarContent
					}
#endif
					
					if let account = selectedAccount {
						let session = VercelSession(account: account)
						ProjectsListView()
							.environmentObject(session)
							.navigationTitle(Text("Projects"))
					} else {
						PlaceholderView(forRole: .NoProjects)
					}
					
					PlaceholderView(forRole: .ProjectDetail)
						.navigationTitle(Text("Project Details"))
				}
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
