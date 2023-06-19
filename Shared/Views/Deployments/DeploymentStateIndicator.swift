//
//  DeploymentStateIndicator.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

enum StateIndicatorStyle {
	case normal, compact
}

struct DeploymentStateIndicator: View {
	var state: VercelDeployment.State
	var style: StateIndicatorStyle = .normal

	var label: String {
		state.description
	}

	var color: Color {
		state.color
	}

	var iconName: String {
		state.imageName
	}

	var body: some View {
		if #available(iOS 17.0, *) {
			return Group {
				if style == .normal {
					Label(label, systemImage: iconName)
				} else {
					Label(label, systemImage: iconName)
						.labelStyle(IconOnlyLabelStyle())
				}
			}
			.foregroundStyle(color)
			.symbolVariant(.fill)
			.symbolRenderingMode(.hierarchical)
			.contentTransition(.symbolEffect(.replace.downUp.byLayer))
		} else {
			return Group {
				if style == .normal {
					Label(label, systemImage: iconName)
				} else {
					Label(label, systemImage: iconName)
						.labelStyle(IconOnlyLabelStyle())
				}
			}
			.foregroundStyle(color)
			.symbolVariant(.fill)
			.symbolRenderingMode(.hierarchical)
		}
	}
}

struct DeploymentStateIndicator_Previews: PreviewProvider {
	static var previews: some View {
		Group {
			ForEach(VercelDeployment.State.allCases, id: \.self) { state in
				DeploymentStateIndicator(state: state)
			}

			ForEach(VercelDeployment.State.allCases, id: \.self) { state in
				DeploymentStateIndicator(state: state, style: .compact)
			}
		}.previewLayout(.sizeThatFits)
	}
}
