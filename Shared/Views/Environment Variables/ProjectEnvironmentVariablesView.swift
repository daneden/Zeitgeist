//
//  ProjectEnvironmentVariablesView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/09/2022.
//

import SwiftUI
import LocalAuthentication
import Suite

struct ProjectEnvironmentVariablesView: View {
	@EnvironmentObject var session: VercelSession
	@AppStorage(Preferences.lastAuthenticated) var lastAuthenticated
	@AppStorage(Preferences.authenticationTimeout) var authenticationTimeout
	@State private var envVars: [VercelEnv] = []
	@State private var editSheetPresented = false
	
	var isAuthenticated: Bool {
		abs(lastAuthenticated.distance(to: .now)) < authenticationTimeout
	}
	
	var projectId: VercelProject.ID
	
	var body: some View {
		ZStack {
			Form {
				if isAuthenticated {
					Section {
						ForEach(envVars) { envVar in
							EnvironmentVariableRowView(projectId: projectId, envVar: envVar)
								.id(envVar.hashValue)
								.draggable(envVar)
								.contentShape(Rectangle())
						}
					} footer: {
						Label {
							Text("Environment variables with Vercel Secrets values are indicated by a padlock icon. Note that creating and updating Secrets is not currently supported.")
						} icon: {
							Image(systemName: "lock")
						}
					}
				}
			}
			.toolbar {
				Button {
					editSheetPresented = true
				} label: {
					Label("Add new environment variable", systemImage: "plus")
						.backportCircleSymbolVariant()
				}
			}
			.navigationTitle(Text("Environment variables"))
			.onAppear {
				if !isAuthenticated {
					authenticate()
				}
			}
			.dataTask {
				await loadEnvironmentVariables()
			}
			.sheet(isPresented: $editSheetPresented) {
				NavigationView {
					EnvironmentVariableEditView(projectId: projectId)
				}
			}
			
			if !isAuthenticated {
				VStack(spacing: 8) {
					Image(systemName: "lock")
						.font(.largeTitle)
						.symbolVariant(.fill)
					Text("Authentication required")
						.font(.title3)
					Button {
						authenticate()
					} label: {
						Text("Authenticate")
					}.buttonStyle(.bordered)
				}
				.foregroundStyle(.secondary)
			} else if envVars.isEmpty {
				PlaceholderView(forRole: .NoEnvVars)
			}
		}
#if !os(macOS)
		.listStyle(.insetGrouped)
#endif
		.animation(.default, value: isAuthenticated)
	}
	
	func loadEnvironmentVariables() async {
		do {
			var request = VercelAPI.request(for: .projects(projectId, path: "env"), with: session.account.id)
			try session.signRequest(&request)
			
			let (data, _) = try await URLSession.shared.data(for: request)
			try withAnimation {
				envVars = try JSONDecoder().decode(VercelEnv.APIResponse.self, from: data).envs
			}
		} catch {
			print(error)
		}
	}
	
	func authenticate() {
		let context = LAContext()
		var error: NSError?
		
		if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
			let reason = "Authentication is required to view decrypted environment variables"
			
			context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, authError in
				if success {
					lastAuthenticated = .now
				}
				
				if let authError = authError {
					print(authError)
				}
			}
		} else {
			// No auth method available
		}
	}
}

struct ProjectEnvironmentVariablesView_Previews: PreviewProvider {
	static var previews: some View {
		ProjectEnvironmentVariablesView(projectId: "nrrrdcore")
	}
}
