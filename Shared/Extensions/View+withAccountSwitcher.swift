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
					Button {
						presentAccountManagementView = true
					} label: {
						VercelUserAvatarView(account: accountManager.selectedAccount)
							.accessibilityLabel("Manage accounts")
					}
					.buttonBorderShape(.circle)
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
