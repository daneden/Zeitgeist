//
//  EnvironmentVariableEditView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/09/2022.
//

import SwiftUI

struct EnvironmentVariableEditView: View {
	@EnvironmentObject var session: VercelSession
	@Environment(\.dismiss) private var dismiss
	
	var projectId: VercelProject.ID
	var id: VercelEnv.ID?
	@State var key = ""
	@State var value = ""
	
	@State var targetProduction = true
	@State var targetPreview = true
	@State var targetDevelopment = true
	@State private var saving = false
	
	private var envVarIsValid: Bool {
		(targetPreview || targetProduction || targetDevelopment) &&
		key.range(of: #"^[a-zA-Z][_\w]*$"#, options: .regularExpression) != nil
	}
	
	var body: some View {
		Form {
			Section {
				TextField("Name", text: $key)
					.font(.body.monospaced())
					.autocorrectionDisabled(true)
			} footer: {
				Text("Environment variable names must begin with a letter and can only contain letters, numbers, and underscores")
			}
			
			Section("Value") {
				TextEditor(text: $value)
					.font(.body.monospaced())
					.frame(minHeight: 80)
					.autocorrectionDisabled(true)
			}
			
			Section {
				Toggle(isOn: $targetProduction) {
					Text("Production")
				}
				
				Toggle(isOn: $targetPreview) {
					Text("Preview")
				}
				
				Toggle(isOn: $targetDevelopment) {
					Text("Development")
				}
			} header: {
				Text("Environment")
			} footer: {
				Text("At least one target must be selected. For more advanced settings, such as custom Git branch configuration for Preview targets, configure your environment variable on Vercel’s website.")
			}
			
			Section {
				Button {
					Task {
						await saveEnvVar()
					}
				} label: {
					HStack {
						Text("Submit", comment: "Button label to save a new environment variable")
						
						if saving {
							Spacer()
							ProgressView()
						}
					}
				}
				.disabled(!envVarIsValid)
				.disabled(saving)
			} footer: {
				Text("A new deployment is required for your changes to take effect.")
			}
		}
		.navigationTitle(Text("\(id == nil ? "Add" : "Edit") Environment Variable", comment: "Navigation title for either adding or editing an env var"))
		.toolbar {
			Button {
				dismiss()
			} label: {
				Text("Cancel")
			}
		}
		#if os(iOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
	}
	
	func saveEnvVar() async {
		saving = true
		
		do {
			var path = "env"
			var method: VercelAPI.RequestMethod = .POST
			if let id {
				path += "/\(id)"
				method = .PATCH
			}
			var request: URLRequest = VercelAPI.request(for: .projects(projectId, path: path), with: session.account.id, method: method)
			
			var targets = [String]()
			
			if targetProduction { targets.append("production") }
			if targetPreview { targets.append("preview") }
			if targetDevelopment { targets.append("development") }
			
			let body: [String: Any] = [
				"key": key,
				"value": value,
				"target": targets,
				"type": "encrypted"
			]
			
			let encoded = try JSONSerialization.data(withJSONObject: body)
			request.httpBody = encoded
			
			try session.signRequest(&request)
			let (data, _) = try await URLSession.shared.data(for: request)
			
			let response = try JSONDecoder().decode(VercelEnv.self, from: data)
			print("Successfully created/updated env var with key \(response.key)")
			
			dismiss()
			DataTaskModifier.postNotification()
		} catch {
			print(error)
		}
		
		saving = false
	}
}

struct EnvironmentVariableEditView_Previews: PreviewProvider {
    static var previews: some View {
			EnvironmentVariableEditView(projectId: "nrrrdcore")
    }
}
