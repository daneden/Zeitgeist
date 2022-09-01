//
//  DeploymentFilterView.swift
//  Verdant
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

struct DeploymentFilter: Codable, Hashable {
	var state: VercelDeployment.State?
	var target: VercelDeployment.Target?
	
	var filtersApplied: Bool {
		state != nil || target != nil
	}
	
	var urlQueryItems: [URLQueryItem] {
		var queryItems: [URLQueryItem] = []
		if let state = state {
			queryItems.append(URLQueryItem(name: "state", value: state.rawValue))
		}
		
		if let target = target {
			queryItems.append(URLQueryItem(name: "target", value: target.rawValue))
		}
		
		return queryItems
	}
}

struct DeploymentFilterView: View {
	@Environment(\.presentationMode) var presentationMode
	@Binding var filter: DeploymentFilter

	var body: some View {
		Form {
			Section(header: Text("Filter deployments by:")) {
				Picker("Status", selection: $filter.state.animation()) {
					Text("All statuses").tag(Optional<VercelDeployment.State>(nil))

					ForEach(VercelDeployment.State.typicalCases, id: \.self) { state in
						DeploymentStateIndicator(state: state)
							.tag(Optional(state))
					}
				}.accentColor(.secondary)
				
				Picker("Target", selection: $filter.target.animation()) {
					Text("All targets").tag(Optional<VercelDeployment.Target>(nil))
					ForEach(VercelDeployment.Target.allCases, id: \.self) { target in
						Text(target.rawValue)
							.tag(Optional(target))
					}
				}
			}

			Section {
				Button(action: {
					withAnimation {
						self.filter = .init()
					}
				}, label: {
					Text("Clear filters")
				})
				.disabled(!filter.filtersApplied)
			}
		}
		.toolbar {
			Button(action: { presentationMode.wrappedValue.dismiss() }) {
				Text("Close")
			}.keyboardShortcut(.cancelAction)
		}
		.navigationTitle("Filter Deployments")
		.makeContainer()
	}
}
