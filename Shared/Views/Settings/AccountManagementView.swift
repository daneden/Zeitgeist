//
//  AccountManagementView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/01/2026.
//
import SwiftUI

struct AccountManagementView: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(\.webAuthenticationSession) private var webAuthenticationSession
	@Environment(AccountManager.self) private var accountManager
	
	@State private var signInViewModel = SignInViewModel()
	
	var body: some View {
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
								
								if account == accountManager.selectedAccount {
									Image(systemName: "checkmark")
										.foregroundStyle(.tint)
								}
							}
						}
						.buttonStyle(.plain)
						.contextMenu {
							Button("Sign out", systemImage: "person.badge.minus", role: .destructive) {
								accountManager.deleteAccount(id: account.id)
							}
						}
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
					#if os(macOS)
					.buttonStyle(.borderless)
					#endif
					
					Button("Sign out of all accounts", systemImage: "person.2.badge.minus", role: .destructive) {
						deleteAllAccounts()
						dismiss()
					}
					#if os(macOS)
					.buttonStyle(.borderless)
					#endif
				}
			}
			.toolbar {
				#if os(iOS)
				ToolbarItem(placement: .primaryAction) {
					EditButton()
				}
				#endif
				
				ToolbarItem(placement: .cancellationAction) {
					BackportCloseButton { dismiss() }
				}
			}
			.navigationTitle("Accounts")
		}
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

