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
	@State private var presentOnboardingView = false
	
	var body: some View {
		AuthenticatedContentView()
			.formStyle(.grouped)
			.animation(.default, value: accounts.isEmpty)
			.symbolRenderingMode(.hierarchical)
			.onAppear {
				if let lastAppVersionOpened,
					 lastAppVersionOpened == "2" && ZeitgeistApp.majorAppVersion == "3" {
					presentNewFeaturesScreen = true
					self.lastAppVersionOpened = ZeitgeistApp.majorAppVersion
				}
			}
			.sheet(isPresented: $presentNewFeaturesScreen) {
				NewFeaturesView()
			}
			.task(id: accounts.hashValue) {
				presentOnboardingView = accounts.isEmpty
			}
			.sheet(isPresented: $presentOnboardingView) {
				OnboardingView()
					.interactiveDismissDisabled()
#if !os(iOS)
					.frame(minWidth: 800, minHeight: 600)
#endif
			}
	}
}
