//
//  DeploymentFilterView.swift
//  Verdant
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

struct DeploymentFilter: Codable, Hashable {
	var state: VercelDeployment.State?
	var productionOnly = false
	
	var filtersApplied: Bool {
		state != nil || productionOnly
	}
	
	var urlQueryItems: [URLQueryItem] {
		var queryItems: [URLQueryItem] = []
		if let state = state {
			queryItems.append(URLQueryItem(name: "state", value: state.rawValue))
		}
		
		if productionOnly {
			queryItems.append(URLQueryItem(name: "target", value: "production"))
		}
		
		return queryItems
	}
}

struct DeploymentFilterView: View {
	@Environment(\.dismiss) var dismiss
	@Binding var filter: DeploymentFilter

	var body: some View {
		Section(header: Text("Filter deployments by:")) {
			Picker("Status", selection: $filter.state.animation()) {
				Text("All statuses").tag(Optional<VercelDeployment.State>(nil))

				ForEach(VercelDeployment.State.typicalCases, id: \.self) { state in
					DeploymentStateIndicator(state: state)
						.tag(Optional(state))
				}
			}.accentColor(.secondary)
			
			Toggle(isOn: $filter.productionOnly.animation()) {
				Label("Production deployments only", systemImage: "theatermasks")
					.symbolVariant(filter.productionOnly ? .fill : .none)
			}
		}
		
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
