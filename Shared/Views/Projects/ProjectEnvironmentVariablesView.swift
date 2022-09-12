//
//  ProjectEnvironmentVariablesView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/09/2022.
//

import SwiftUI
import LocalAuthentication

fileprivate struct EnvironmentVariableRowView: View {
	@State private var isExpanded = false
	var envVar: VercelEnv
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(envVar.key)
					.lineLimit(2)
					.font(.footnote.monospaced())
				
				Spacer()
				
				Text(envVar.updated, style: .relative)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			HStack {
				if envVar.type == .secret {
					Image(systemName: "lock")
				}
				
				Text(envVar.value)
					.privacySensitive(true)
			}
				.lineLimit(isExpanded ? nil : 2)
				.font(.footnote.monospaced())
				.foregroundStyle(.secondary)
			
			Text(envVar.target.joined(separator: ", ").capitalized)
				.font(.caption)
				.foregroundStyle(.tertiary)
				.textSelection(.disabled)
		}
		.onTapGesture {
			isExpanded.toggle()
		}
		.textSelection(.enabled)
		.contextMenu {
			Button {
				Pasteboard.setString("\(envVar.key)=\(envVar.value)")
			} label: {
				Label("Copy", systemImage: "doc.on.doc")
			}
		}
	}
}

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
						EnvironmentVariableRowView(envVar: envVar)
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
					EnvironmentVariableEditView()
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
		}.animation(.default, value: isAuthenticated)
	}
	
	func loadEnvironmentVariables() async {
		do {
			var queryItems: [URLQueryItem] = [
				URLQueryItem(name: "decrypt", value: "true")
			]
			var request = VercelAPI.request(for: .projects(projectId, path: "env"), with: session.account.id, queryItems: queryItems)
			try session.signRequest(&request)
			
			let (data, _) = try await URLSession.shared.data(for: request)
			envVars = try JSONDecoder().decode(VercelEnv.APIResponse.self, from: data).envs
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
