//
//  EnvironmentVariableEditView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/09/2022.
//

import SwiftUI

struct EnvironmentVariableEditView: View {
	@Environment(\.dismiss) private var dismiss
	
	var id: VercelEnv.ID?
	@State var key = ""
	@State var value = ""
	
	@State var targetProduction = true
	@State var targetPreview = true
	@State var targetDevelopment = true
	
	private var envVarIsValid: Bool {
		(targetPreview || targetProduction || targetDevelopment) &&
		!value.isEmpty && !key.isEmpty &&
		key.range(of: #"^[a-zA-Z][_\w]*"#, options: .regularExpression) != nil
	}
	
	var body: some View {
		Form {
			Section {
				TextField("Name", text: $key)
					.font(.body.monospaced())
				TextField("Value", text: $value)
					.font(.body.monospaced())
			} footer: {
				Text("Environment variable names must begin with a letter and can only contain letters, numbers, and underscores")
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
			
			Button {
				print(key)
				print(value)
			} label: {
				Text("Submit")
			}.disabled(!envVarIsValid)
		}
		.navigationTitle("\(id == nil ? "Add" : "Edit") Environment Variable")
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
}

struct EnvironmentVariableEditView_Previews: PreviewProvider {
    static var previews: some View {
        EnvironmentVariableEditView()
    }
}
