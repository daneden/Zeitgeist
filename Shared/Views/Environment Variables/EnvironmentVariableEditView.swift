//
//  EnvironmentVariableEditView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/09/2022.
//

import SwiftUI

struct EnvironmentVariableEditView: View {
	@Environment(\.session) private var session
	@Environment(\.dismiss) private var dismiss

	var projectId: VercelProject.ID
	var id: VercelEnv.ID?
	@State private var key: String
	@State private var value: String

	@State private var targetProduction: Bool
	@State private var targetPreview: Bool
	@State private var targetDevelopment: Bool
	@State private var saving = false

	init(
		projectId: VercelProject.ID,
		id: VercelEnv.ID? = nil,
		key: String = "",
		value: String = "",
		targetProduction: Bool = true,
		targetPreview: Bool = true,
		targetDevelopment: Bool = true
	) {
		self.projectId = projectId
		self.id = id
		_key = State(initialValue: key)
		_value = State(initialValue: value)
		_targetProduction = State(initialValue: targetProduction)
		_targetPreview = State(initialValue: targetPreview)
		_targetDevelopment = State(initialValue: targetDevelopment)
	}

	private var envVarIsValid: Bool {
		(targetPreview || targetProduction || targetDevelopment) &&
			key.range(of: #"^[a-zA-Z][_\w]*$"#, options: .regularExpression) != nil
	}

	var navBarTitle: Text {
		switch id {
		case .none: return Text("Add environment variable")
		case .some: return Text("Edit environment variable")
		}
	}

	var body: some View {
		NavigationStack {
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
			}
			.navigationTitle(navBarTitle)
			.toolbar {
				ToolbarItem(placement: .confirmationAction) {
					Button {
						Task {
							await saveEnvVar()
						}
					} label: {
						Label {
							Text("Done")
						} icon: {
							if saving {
								ProgressView()
							} else {
								Image(systemName: "checkmark")
							}
						}
					}
					.labelStyle(.iconOnly)
					.disabled(!envVarIsValid)
					.disabled(saving)
				}
				ToolbarItem(placement: .cancellationAction) {
					BackportCloseButton {
						dismiss()
					}
				}
			}
			#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
			#endif
		}
	}

	func saveEnvVar() async {
		guard let session else { return }
		saving = true

		let targets = EnvironmentVariableService.buildTargets(
			production: targetProduction,
			preview: targetPreview,
			development: targetDevelopment
		)

		do {
			let response: VercelEnv
			if let id {
				response = try await EnvironmentVariableService.update(
					projectId: projectId,
					envVarId: id,
					key: key,
					value: value,
					targets: targets,
					session: session
				)
			} else {
				response = try await EnvironmentVariableService.create(
					projectId: projectId,
					key: key,
					value: value,
					targets: targets,
					session: session
				)
			}
			print("Successfully created/updated env var with key \(response.key)")

			dismiss()
			DataTaskModifier.postNotification(scope: .project)
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
