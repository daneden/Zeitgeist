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
	
	@State var initialising = false

	var body: some View {
		Group {
			if !session.isAuthenticated || session.account == nil {
				ProjectListPlaceholderView()
					.sheet(isPresented: $initialising) {
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
			
			initialising = accounts.isEmpty
		}
		.onReceive(session.objectWillChange) { _ in
			initialising = !session.isAuthenticated
		}
		.onAppear {
			withAnimation {
				session.account = accounts.first
			}
			
			initialising = !session.isAuthenticated
		}
		.environmentObject(session)
	}
}
