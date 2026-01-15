//
//  View+withAccountSwitcher.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/01/2026.
//

import SwiftUI

struct WithAccountSwitcherModifier: ViewModifier {
	@Environment(AccountManager.self) private var accountManager
	
	@State private var presentSettingsView = false
	@State private var presentAccountManagementView = false
	
	func body(content: Content) -> some View {
		content
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
				AccountManagementView()
					.presentationDetents([.medium, .large])
			}
	}
}

extension View {
	func withAccountSwitcher() -> some View {
		modifier(WithAccountSwitcherModifier())
	}
}
