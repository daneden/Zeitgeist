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
			Text(account.name ?? account.username)
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
						Text("Accounts")
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
					Text("Select an account")
				}
			} detail: {
				NavigationStack {
					PlaceholderView(forRole: .ProjectDetail)
				}
			}
			.onAppear {
				if let account = accounts.first {
					selectedAccount = account
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
				
				if let account = accounts.first {
					let session = VercelSession(account: account)
					
					ProjectsListView()
						.environmentObject(session)
						.navigationTitle("Projects")
				} else {
					PlaceholderView(forRole: .NoProjects)
				}
				
				PlaceholderView(forRole: .ProjectDetail)
					.navigationTitle("Project Details")
			}
		}
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
