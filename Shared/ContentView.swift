//
//  ContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 17/08/2022.
//

import SwiftUI

struct ContentView: View {
	@AppStorage(Preferences.authenticatedAccounts) var accounts
	@AppStorage(Preferences.lastAppVersionOpened) private var lastAppVersionOpened
	
	@State private var presentNewFeaturesScreen = false

	var body: some View {
		Group {
			if #available(iOS 16.0, *) {
				AuthenticatedContentView()
					.formStyle(.grouped)
			} else {
				AuthenticatedContentView()
			}
		}
		.animation(.default, value: accounts.isEmpty)
		.symbolRenderingMode(.hierarchical)
		.onAppear {
			if let lastAppVersionOpened = lastAppVersionOpened,
				 lastAppVersionOpened == "2" && ZeitgeistApp.majorAppVersion == "3" {
				presentNewFeaturesScreen = true
				self.lastAppVersionOpened = ZeitgeistApp.majorAppVersion
			}
		}
		.sheet(isPresented: $presentNewFeaturesScreen) {
			NewFeaturesView()
		}
		.sheet(isPresented: .constant(accounts.isEmpty)) {
			OnboardingView()
				.interactiveDismissDisabled()
		}
	}
}
