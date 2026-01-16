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
	@Environment(\.session) private var session
	@Environment(\.dismiss) private var dismiss
	@AppStorage(Preferences.lastAuthenticated) var lastAuthenticated
	@AppStorage(Preferences.authenticationTimeout) var authenticationTimeout
	@State private var envVars: [VercelEnv] = []
	@State private var editSheetPresented = false
	@State private var isLoading = false
	@State private var sortOrder = [KeyPathComparator(\VercelEnv.key)]
	
	var isAuthenticated: Bool {
		abs(lastAuthenticated.distance(to: .now)) < authenticationTimeout
	}
	
	var projectId: VercelProject.ID
	
	var body: some View {
		NavigationStack {
			Form {
				if isAuthenticated {
					#if os(macOS)
					Table(of: VercelEnv.self, sortOrder: $sortOrder) {
						TableColumn("Key", value: \.key) {
							Text($0.key)
								.monospaced()
								.lineLimit(3)
						}
						.width(min: 80, ideal: 120, max: 240)

						TableColumn("Value") { envVar in
							EnvironmentVariableDecryptingView(projectId: projectId, envVar: envVar)
								.lineLimit(100)
						}
						.width(min: 120, ideal: 240, max: 500)
						
						TableColumn("Last updated", value: \.updated) { envVar in
							Text(envVar.updated.formatted())
								.lineLimit(2)
						}
						.width(min: 80, ideal: 120, max: 240)
						
						TableColumn("Targets") { envVar in
							Text(envVar.target.map { $0.capitalized }.formatted(.list(type: .and)))
								.lineLimit(3)
						}
						.width(min: 80, ideal: 120, max: 240)
					} rows: {
						ForEach(envVars.sorted(using: sortOrder)) { envVar in
							TableRow(envVar)
						}
					}
					.tableStyle(.bordered)
					#elseif os(iOS)
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
					#endif
				}
			}
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						editSheetPresented = true
					} label: {
						Label("Add environment variable", systemImage: "plus")
							.backportCircleSymbolVariant()
					}
				}
				
				ToolbarItem(placement: .cancellationAction) {
					BackportCloseButton {
						dismiss()
					}
				}
			}
			.navigationTitle(Text("Environment variables"))
			.onAppear {
				if !isAuthenticated {
					authenticate()
				}
			}
			.zeitgeistDataTask {
				await loadEnvironmentVariables()
			}
			.sheet(isPresented: $editSheetPresented) {
				NavigationStack {
					EnvironmentVariableEditView(projectId: projectId)
				}
			}
			.overlay {
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
				} else if envVars.isEmpty, !isLoading {
					PlaceholderView(forRole: .NoEnvVars)
				}
			}
		}
		#if !os(macOS)
		.listStyle(.insetGrouped)
		#endif
		.animation(.default, value: isAuthenticated)
	}
	
	func loadEnvironmentVariables() async {
		guard let session else { return }
		isLoading = true
		
		defer { isLoading = false }
		
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
