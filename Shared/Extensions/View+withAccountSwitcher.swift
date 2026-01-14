//
//  View+withAccountSwitcher.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/01/2026.
//

import SwiftUI

struct WithAccountSwitcherModifier: ViewModifier {
	@Environment(\.webAuthenticationSession) private var webAuthenticationSession
	@Environment(\.dismiss) private var dismiss
	@Environment(\.editMode) private var editMode
	@Environment(AccountManager.self) private var accountManager
	
	@State private var presentSettingsView = false
	@State private var presentAccountManagementView = false
	
	@State private var signInViewModel = SignInViewModel()
	
	func body(content: Content) -> some View {
		content
		#if os(macOS)
			.backportSafeAreaBar {
				Picker(selection: Binding(
					get: { accountManager.selectedAccount },
					set: { accountManager.selectedAccountId = $0?.id }
				)) {
					ForEach(accountManager.accounts, id: \.self) { account in
						AccountListRowView(account: account)
					}
				} label: {
					Text("Accounts")
				}
			}
		#elseif os(iOS)
			.toolbar {
				ToolbarItem(placement: .navigation) {
					Menu {
						if let selectedAccount = accountManager.selectedAccount {
							Section("Signed in as") {
								AccountListRowView(account: selectedAccount)
							}
						}
						
						Button("Manage accounts") {
							presentAccountManagementView = true
						}
					} label: {
						VercelUserAvatarView(account: accountManager.selectedAccount)
							.accessibilityLabel("Accounts and settings")
					}
				}
				
				ToolbarItem(placement: .secondaryAction) {
					Button("Settings", systemImage: "gearshape") {
						presentSettingsView = true
					}
				}
			}
			.sheet(isPresented: $presentSettingsView) {
				NavigationStack {
					SettingsView()
				}
			}
			.sheet(isPresented: $presentAccountManagementView) {
				NavigationStack {
					List {
						Section {
							ForEach(accountManager.accounts) { account in
								Button {
									accountManager.selectAccount(account)
								} label: {
									HStack {
										AccountListRowView(account: account)
											.frame(maxWidth: .infinity, alignment: .leading)
										
										if account == accountManager.selectedAccount,
											 editMode?.wrappedValue.isEditing == false {
											Image(systemName: "checkmark")
												.foregroundStyle(.tint)
										}
									}
								}
								.buttonStyle(.plain)
							}
							.onDelete(perform: deleteAccounts)
						}
						
						Section {
							Button {
								Task {
									await signInViewModel.signIn(using: webAuthenticationSession, accountManager: accountManager)
								}
							} label: {
								HStack {
									Label("Add account", systemImage: "person.badge.plus")
									Spacer()
									
									if signInViewModel.isSigningIn {
										ProgressView()
											.controlSize(.small)
									}
								}
							}
							.disabled(signInViewModel.isSigningIn)
							
							Button("Sign out of all accounts", systemImage: "person.2.badge.minus", role: .destructive) {
								deleteAllAccounts()
								dismiss()
							}
						}
					}
					.toolbar {
						EditButton()
					}
				}
			}
		#endif
	}
	
	func deleteAllAccounts() {
		for account in accountManager.accounts {
			accountManager.deleteAccount(id: account.id)
		}
	}
	
	func deleteAccounts(at offsets: IndexSet) {
		// Safely map offsets to the current accounts array and remove via AccountManager
		let accountsToRemove: [VercelAccount] = offsets.compactMap { index in
			guard index >= 0 && index < accountManager.accounts.count else { return nil }
			return accountManager.accounts[index]
		}
		
		for account in accountsToRemove {
			accountManager.deleteAccount(id: account.id)
		}
	}
}

extension View {
	func withAccountSwitcher() -> some View {
		modifier(WithAccountSwitcherModifier())
	}
}
