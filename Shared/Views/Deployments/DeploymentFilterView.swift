//
//  DeploymentFilterView.swift
//  Verdant
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

enum StateFilter: Hashable {
	case allStates
	case filteredByState(state: VercelDeployment.State)
}

enum TargetFilter: Hashable {
	case allTargets
	case filteredByTarget(target: VercelDeployment.Target)
}

struct DeploymentFilterView: View {
	@Environment(\.presentationMode) var presentationMode

	@Binding var stateFilter: StateFilter
	@Binding var productionFilter: Bool

	var filtersApplied: Bool {
		return
			productionFilter ||
			stateFilter != .allStates
	}

	var body: some View {
		Form {
			Section(header: Text("Filter deployments by:")) {
				Picker("Status", selection: $stateFilter.animation()) {
					Text("All statuses").tag(StateFilter.allStates)

					ForEach(VercelDeployment.State.typicalCases, id: \.self) { state in
						DeploymentStateIndicator(state: state)
							.tag(StateFilter.filteredByState(state: state))
					}
				}.accentColor(.secondary)

				Toggle(isOn: self.$productionFilter.animation()) {
					Label("Production Deployments Only", systemImage: "theatermasks")
						.symbolVariant(.fill)
				}.toggleStyle(SwitchToggleStyle(tint: .accentColor))
			}

			Section {
				Button(action: {
					withAnimation {
						self.productionFilter = false
						self.stateFilter = .allStates
					}
				}, label: {
					Text("Clear filters")
				})
				.disabled(!filtersApplied)
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
