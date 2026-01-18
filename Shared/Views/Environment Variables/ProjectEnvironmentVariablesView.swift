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
	
	@State var envVars: [VercelEnv] = []
	var projectId: VercelProject.ID
	
	@State private var editSheetPresented = false
	@State private var isLoading = false
	
	var isAuthenticated: Bool {
		abs(lastAuthenticated.distance(to: .now)) < authenticationTimeout
	}
	
	var body: some View {
		NavigationStack {
			Group {
				if !isAuthenticated {
					ContentUnavailableView {
						Label("Authentication required", systemImage: "lock")
					} description: {
						
					} actions: {
						Button("Unlock") {
							authenticate()
						}
					}
				} else if envVars.isEmpty {
						ContentUnavailableView("No environment variables", systemImage: "text.magnifyingglass")
				} else {
					Form {
						#if os(macOS)
						EnvironmentVariablesTableView(envVars: envVars, projectId: projectId)
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
			#if !os(macOS)
			.listStyle(.insetGrouped)
			#endif
			.animation(.default, value: isAuthenticated)
		}
	}
	
	func loadEnvironmentVariables() async {
		guard let session else { return }
		isLoading = true

		defer { isLoading = false }

		do {
			let fetched = try await EnvironmentVariableService.fetchAll(
				projectId: projectId,
				session: session
			)
			withAnimation {
				envVars = fetched
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

struct EnvironmentVariablesTableView: View {
	@Environment(\.session) private var session
	var envVars: [VercelEnv] = []
	var projectId: VercelProject.ID
	
	@State private var sortOrder = [KeyPathComparator(\VercelEnv.key)]
	
	@State private var editingEnv: VercelEnv?
	
	var body: some View {
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
					.contextMenu {
						Button("Edit", systemImage: "pencil") {
							editingEnv = envVar
						}
						.sheet(item: $editingEnv) { envVar in
							EnvironmentVariableEditView(
								projectId: projectId,
								id: envVar.id,
								key: envVar.key,
								value: envVar.value,
								targetProduction: envVar.targetsProduction,
								targetPreview: envVar.targetsPreview,
								targetDevelopment: envVar.targetsDevelopment)
						}
						
						Button("Delete", systemImage: "trash", role: .destructive) {
							guard let session else { return }
							Task {
								do {
									try await EnvironmentVariableService.delete(projectId: projectId, envVarId: envVar.id, session: session)
								} catch {
									print(error.localizedDescription)
								}
							}
						}
					}
			}
		}
		#if os(macOS)
		.tableStyle(.bordered)
		#endif
	}
}

struct ProjectEnvironmentVariablesView_Previews: PreviewProvider {
	static var previews: some View {
		ProjectEnvironmentVariablesView(projectId: "nrrrdcore")
	}
}
