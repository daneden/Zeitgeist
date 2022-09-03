//
//  DeploymentListRowView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct DeploymentListRowView: View {
	var deployment: VercelDeployment
	var projectName: String?

	var body: some View {
		return Label {
				VStack(alignment: .leading) {
					HStack(spacing: 4) {
						if deployment.target == .production {
							Label("Production Deployment", systemImage: "theatermasks")
								.labelStyle(.iconOnly)
								.foregroundStyle(.tint)
								.symbolVariant(.fill)
								.imageScale(.small)
						}
						
						Text(deployment.project)
					}
					.font(.footnote.bold())
					
					switch deployment.deploymentCause {
					case let .deployHook(name):
						Text("\(Image(deployment.deploymentCause.icon!)) \(name)")
							.lineLimit(2)
							.imageScale(.small)
					default:
						Text(deployment.deploymentCause.description)
							.lineLimit(2)
					}
					
					VStack(alignment: .leading, spacing: 2) {
						Text("\(deployment.created, style: .relative) ago")
							.fixedSize()
							.foregroundStyle(.secondary)
							.font(.caption)
					}
				}
			} icon: {
			DeploymentStateIndicator(state: deployment.state, style: .compact)
		}
	}
}
