//
//  ProjectEnvironmentVariablesView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/09/2022.
//

import SwiftUI
import LocalAuthentication

struct ProjectEnvironmentVariablesView: View {
	@EnvironmentObject var session: VercelSession
	@State private var envVars: [VercelEnv] = []
	@State private var isAuthenticated = false
	@State private var editSheetPresented = false
	
	var projectId: VercelProject.ID
	
	var body: some View {
		ZStack {
			List {
				if isAuthenticated {
					ForEach(envVars) { envVar in
						EnvironmentVariableRowView(projectId: projectId, envVar: envVar)
					}
				}
			}
			.toolbar {
				Button {
					editSheetPresented = true
				} label: {
					Label("Add new environment variable", systemImage: "plus.circle")
				}
			}
			.listStyle(.insetGrouped)
			.navigationTitle("Environment Variables")
			.onAppear {
				authenticate()
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
				VStack {
					Image(systemName: "lock")
						.font(.largeTitle)
						.symbolVariant(.fill)
					Text("Authentication Required")
						.font(.title3)
				}
				.foregroundStyle(.secondary)
			} else if envVars.isEmpty {
				PlaceholderView(forRole: .NoEnvVars)
			}
		}
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
				isAuthenticated = success
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
