//
//  StatusBannerView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 22/08/2022.
//

import SwiftUI

struct StatusBannerView: View {
	var states: [VercelDeployment.State] = [.building, .ready, .queued, .error]
	
	var body: some View {
		VStack(spacing: 16) {
			ForEach(0..<12, id: \.self) { _ in
				HStack(spacing: 16) {
					ForEach(0..<6, id: \.self) { i in
						let state = states[Int.random(in: 0...(states.count-1))]
						
						if Int.random(in: 0...4).isMultiple(of: 3) {
							DeploymentStateIndicator(state: state, style: .compact).fixedSize()
						} else {
							DeploymentStateIndicator(state: state).fixedSize()
						}
					}
				}
			}
		}
		.symbolVariant(.fill)
		.symbolRenderingMode(.hierarchical)
		.mask {
			LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
		}
		.opacity(0.5)
		.rotationEffect(.degrees(-5))
		.accessibilityHidden(true)
	}
}

struct StatusBannerView_Previews: PreviewProvider {
    static var previews: some View {
        StatusBannerView()
    }
}
