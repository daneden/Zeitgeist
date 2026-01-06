//
//  DeploymentLiveActivity.swift
//  ZeitgeistWidgetsExtension
//
//  Created by Daniel Eden on 13/04/2024.
//

import SwiftUI
import WidgetKit
import ActivityKit

struct DeploymentAttributes: ActivityAttributes {
	struct ContentState: Codable & Hashable {
		let deploymentState: VercelDeployment.State
	}

	let deploymentId: VercelDeployment.ID
	let deploymentCause: VercelDeployment.DeploymentCause
	let deploymentProject: String
}

struct DeploymentLiveActivity: Widget {
	var body: some WidgetConfiguration {
		ActivityConfiguration(for: DeploymentAttributes.self) { context in
			// Lock screen/banner UI
			HStack(spacing: 12) {
				DeploymentStateIndicator(state: context.state.deploymentState, style: .compact)
					.font(.title2)

				VStack(alignment: .leading, spacing: 4) {
					Text(context.attributes.deploymentProject)
						.font(.headline)
						.lineLimit(1)

					HStack(spacing: 4) {
						DeploymentStateIndicator(state: context.state.deploymentState)
							.font(.subheadline)

						if case .gitCommit(let commit) = context.attributes.deploymentCause {
							Text("·")
								.foregroundStyle(.secondary)
							Text(commit.commitMessage)
								.font(.subheadline)
								.foregroundStyle(.secondary)
								.lineLimit(1)
						} else if case .deployHook(let name) = context.attributes.deploymentCause {
							Text("·")
								.foregroundStyle(.secondary)
							Text(name)
								.font(.subheadline)
								.foregroundStyle(.secondary)
								.lineLimit(1)
						}
					}
				}

				Spacer()
			}
			.padding()
			.activityBackgroundTint(context.state.deploymentState.color.opacity(0.1))
			.activitySystemActionForegroundColor(context.state.deploymentState.color)

		} dynamicIsland: { context in
			DynamicIsland {
				// Expanded UI
				DynamicIslandExpandedRegion(.leading) {
					DeploymentStateIndicator(state: context.state.deploymentState, style: .compact)
						.font(.title2)
				}

				DynamicIslandExpandedRegion(.trailing) {
					if context.state.deploymentState == .building {
						ProgressView()
							.progressViewStyle(.circular)
							.tint(context.state.deploymentState.color)
					}
				}

				DynamicIslandExpandedRegion(.center) {
					VStack(alignment: .leading, spacing: 4) {
						Text(context.attributes.deploymentProject)
							.font(.headline)
							.lineLimit(1)

						if case .gitCommit(let commit) = context.attributes.deploymentCause {
							Text(commit.commitMessage)
								.font(.caption)
								.foregroundStyle(.secondary)
								.lineLimit(2)
						}
					}
				}

				DynamicIslandExpandedRegion(.bottom) {
					HStack {
						DeploymentStateIndicator(state: context.state.deploymentState)
							.font(.caption)
						Spacer()
					}
				}
			} compactLeading: {
				// Compact leading (minimal UI when other activities are present)
				DeploymentStateIndicator(state: context.state.deploymentState, style: .compact)
			} compactTrailing: {
				// Compact trailing
				if context.state.deploymentState == .building {
					ProgressView()
						.progressViewStyle(.circular)
						.tint(context.state.deploymentState.color)
				}
			} minimal: {
				// Minimal UI (when multiple activities)
				DeploymentStateIndicator(state: context.state.deploymentState, style: .compact)
			}
			.contentMargins(.trailing, 20, for: .expanded)
		}
	}
}
