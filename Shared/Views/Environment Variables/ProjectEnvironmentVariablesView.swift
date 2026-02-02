//
//  ProjectEnvironmentVariablesView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/09/2022.
//

import SwiftUI
import LocalAuthentication
import Suite

enum EnvironmentVariableEditingState: Identifiable, Hashable {
	case createNew
	case edit(_ envVar: VercelEnv)
	
	var id: String {
		switch self {
		case .createNew:
			return UUID().uuidString
		case .edit(let envVar):
			return envVar.id
		}
	}
}

struct ProjectEnvironmentVariablesView: View {
	@Environment(\.session) private var session
	@Environment(\.dismiss) private var dismiss
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass
	@AppStorage(Preferences.lastAuthenticated) var lastAuthenticated
	@AppStorage(Preferences.authenticationTimeout) var authenticationTimeout
	
	@State var envVars: [VercelEnv] = []
	var projectId: VercelProject.ID
	
	@State private var editSheetPresented = false
	@State private var isLoading = false
	@State private var sortOrder = [KeyPathComparator(\VercelEnv.key)]
	@State private var editingState: EnvironmentVariableEditingState?
	@State private var pendingDeletion: VercelEnv?
	
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
					Table(of: VercelEnv.self, sortOrder: $sortOrder) {
						TableColumn("Key", value: \.key) {
							if horizontalSizeClass == .compact {
								EnvironmentVariableRowView(projectId: projectId, envVar: $0)
							} else {
								Text($0.key)
									.monospaced()
									.lineLimit(3)
							}
						}
						.width(
							min: horizontalSizeClass == .compact ? nil : 80,
							ideal: horizontalSizeClass == .compact ? nil : 120,
							max: horizontalSizeClass == .compact ? nil : 240
						)
						
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
										if envVar.decrypted == true {
											editingState = .edit(envVar)
										} else {
											Task {
												guard let session,
															let decrypted = try? await EnvironmentVariableService.fetchDecrypted(projectId: projectId, envVarId: envVar.id, session: session) else {
													return
												}
												editingState = .edit(decrypted)
											}
										}
									}
									
									Button("Delete", systemImage: "trash", role: .destructive) {
										pendingDeletion = envVar
									}
								}
						}
					}
					#if os(macOS)
					.tableStyle(.bordered)
					#endif
					.sheet(item: $editingState, onDismiss: {
						Task {
							await loadEnvironmentVariables()
						}
					}) { editingState in
						switch editingState {
						case .edit(let envVar):
							EnvironmentVariableEditView(
								projectId: projectId,
								id: envVar.id,
								key: envVar.key,
								value: envVar.value,
								targetProduction: envVar.targetsProduction,
								targetPreview: envVar.targetsPreview,
								targetDevelopment: envVar.targetsDevelopment
							)
						case .createNew:
							EnvironmentVariableEditView(projectId: projectId)
						}
					}
					.confirmationDialog(
						"Delete environment variable",
						isPresented: .constant(pendingDeletion != nil)
					) {
						Button(role: .cancel) {
							pendingDeletion = nil
						} label: {
							Text("Cancel")
						}
						
						Button(role: .destructive) {
							defer { pendingDeletion = nil }
							guard let pendingDeletion else { return }
							
							Task {
								do {
									try await delete(pendingDeletion)
									DataTaskModifier.postNotification(nil, scope: .project)
								} catch {
									print(error.localizedDescription)
								}
							}
						} label: {
							Text("Delete")
						}
					} message: {
						Text("Are you sure you want to permanently delete this environment variable?")
					}
				}
			}
			.toolbar {
				ToolbarItem(placement: .primaryAction) {
					Button {
						editSheetPresented = true
					} label: {
						Label("Create new...", systemImage: "plus")
							.backportCircleSymbolVariant()
							#if os(macOS)
							.labelStyle(.titleOnly)
							#endif
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
			.zeitgeistDataTask(scope: .project) {
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
	
	func delete(_ envVar: VercelEnv) async throws {
		guard let session else { return }
		
		try await EnvironmentVariableService.delete(projectId: projectId, envVarId: envVar.id, session: session)
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

struct ProjectEnvironmentVariablesView_Previews: PreviewProvider {
	static var previews: some View {
		ProjectEnvironmentVariablesView(projectId: "nrrrdcore")
	}
}
