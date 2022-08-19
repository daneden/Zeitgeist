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
	
	var body: some View {
		Group {
			if !session.isAuthenticated || session.account == nil {
				OnboardingView()
			} else {
				AuthenticatedContentView()
			}
		}
		.symbolRenderingMode(.hierarchical)
		.onChange(of: accounts) { accounts in
			if !accounts.contains(where: { $0.id  == session.account?.id}) {
				withAnimation {
					session.account = accounts.first
				}
			}
		}
		.onAppear {
			print("ContentView first appeared")
			
			withAnimation {
				session.account = accounts.first
			}
		}
		.environmentObject(session)
	}
}
