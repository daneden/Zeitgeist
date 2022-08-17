//
//  ContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 17/08/2022.
//

import SwiftUI

struct ContentView: View {
	@StateObject var session = VercelSession()
	@State private var initialising = true
	
	var body: some View {
		Group {
			if initialising {
				TabView {
					ForEach(0 ..< 3, id: \.self) { _ in
						NavigationView {
							List(0 ..< 20, id: \.self) { _ in
								ProjectsListRowView(project: .exampleData)
							}
							.navigationTitle("Loading")
						}
						.tabItem {
							Label("Loading", systemImage: "folder")
						}
					}
				}.redacted(reason: .placeholder)
			} else {
				if session.isAuthenticated {
					AuthenticatedContentView()
				} else {
					OnboardingView()
				}
			}
		}
		.symbolRenderingMode(.hierarchical)
		.onAppear {
			withAnimation {
				if let account = Preferences.accounts.first {
					session.account = account
				}
				
				initialising = false
			}
		}
		.environmentObject(session)
	}
}
