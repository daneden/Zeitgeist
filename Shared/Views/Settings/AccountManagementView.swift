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
	
	@ViewBuilder
	var addAccountButton: some View {
		Button {
			Task {
				await signInViewModel.signIn(using: webAuthenticationSession, accountManager: accountManager)
			}
		} label: {
			HStack {
				Label("Add account", systemImage: "plus")
				
				if signInViewModel.isSigningIn {
					ProgressView()
						.controlSize(.small)
				}
			}
		}
		.disabled(signInViewModel.isSigningIn)
	}
	
	@ViewBuilder
	var deleteAccountButton: some View {
		Button("Sign out of account", systemImage: "minus") {
			if let selectedAccountId = accountManager.selectedAccountId {
				accountManager.deleteAccount(id: selectedAccountId)
			}
		}
		.disabled(accountManager.selectedAccountId == nil)
	}
	
	@ViewBuilder
	var deleteAllAccountsButton: some View {
		Button("Sign out of all accounts", systemImage: "person.2.badge.minus", role: .destructive) {
			deleteAllAccounts()
			dismiss()
		}
	}
	
	var body: some View {
		@Bindable var accountManager = accountManager
		NavigationStack {
			Group {
				#if os(macOS)
				Table(accountManager.accounts, selection: $accountManager.selectedAccountId) {
					TableColumn("Account") { account in
						AccountListRowView(account: account)
							.environment(self.accountManager)
							.tag(account.id)
					}
					.width(max: .infinity)
				}
				.tableColumnHeaders(.hidden)
				HStack {
					deleteAllAccountsButton
					
					Spacer()
					
					ControlGroup {
						deleteAccountButton
						addAccountButton
					}
					.labelStyle(.iconOnly)
				}
				.padding()
				#elseif os(iOS)
				List {
					Section {
						ForEach(accountManager.accounts) { account in
							Button {
								withAnimation {
									accountManager.selectAccount(account)
								}
							} label: {
								HStack {
									AccountListRowView(account: account)
										.frame(maxWidth: .infinity, alignment: .leading)
									
									if account == accountManager.selectedAccount {
										Image(systemName: "checkmark")
											.foregroundStyle(.tint)
									}
								}
								.contentShape(.rect)
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
						addAccountButton
						deleteAllAccountsButton
							.symbolRenderingMode(.monochrome)
					}
				}
				#endif
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

