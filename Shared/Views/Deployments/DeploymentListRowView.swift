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
						Text("\(Image(deployment.deploymentCause.icon!)) \(name)", comment: "Label for a deployment caused by a deploy hook ({icon} {name})")
							.lineLimit(2)
							.imageScale(.small)
					case .promotion(_):
						Text("\(Image(systemName: "arrow.up.circle")) Production Rebuild", comment: "Label for a deployment caused by a promotion to production")
							.lineLimit(2)
							.imageScale(.small)
					default:
						Text(deployment.deploymentCause.description)
							.lineLimit(2)
					}
					
					VStack(alignment: .leading, spacing: 2) {
						Text("\(deployment.created, style: .relative) ago", comment: "Timestamp for when a deployment was created in a deployment list row")
							.fixedSize()
							.foregroundStyle(.secondary)
							.font(.caption)
							.contentTransition(.numericText())
					}
				}
			} icon: {
			DeploymentStateIndicator(state: deployment.state, style: .compact)
		}
	}
}
