//
//  ContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 17/08/2022.
//

import SwiftUI

struct ContentView: View {
	@AppStorage(Preferences.authenticatedAccounts) var accounts
	@StateObject var session = VercelSession()
	@AppStorage(Preferences.lastAppVersionOpened) private var lastAppVersionOpened
	
	@State private var presentSignInView = false
	@State private var presentNewFeaturesScreen = false

	var body: some View {
		Group {
			if !session.isAuthenticated || session.account == nil {
				ProjectListPlaceholderView()
					.sheet(isPresented: $presentSignInView) {
						OnboardingView()
							.interactiveDismissDisabled()
					}
			} else {
				AuthenticatedContentView()					
			}
		}
		.symbolRenderingMode(.hierarchical)
		.onChange(of: accounts) { accounts in
			if !accounts.contains(where: { $0.id  == session.account?.id}) {
				withAnimation(.interactiveSpring()) {
					session.account = accounts.first
				}
			}
			
			presentSignInView = accounts.isEmpty
		}
		.onReceive(session.objectWillChange) { _ in
			presentSignInView = !session.isAuthenticated
		}
		.onAppear {
			withAnimation {
				session.account = accounts.first
			}
			
			presentSignInView = !session.isAuthenticated
			
			if let lastAppVersionOpened = lastAppVersionOpened,
				 lastAppVersionOpened == "2" && ZeitgeistApp.majorAppVersion == "3" {
				presentNewFeaturesScreen = true
				self.lastAppVersionOpened = ZeitgeistApp.majorAppVersion
			}
		}
		.sheet(isPresented: $presentNewFeaturesScreen) {
			NewFeaturesView()
		}
		.environmentObject(session)
	}
}
