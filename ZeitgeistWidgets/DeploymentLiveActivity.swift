//
//  DeploymentLiveActivity.swift
//  ZeitgeistWidgetsExtension
//
//  Created by Daniel Eden on 13/04/2024.
//

import SwiftUI
import WidgetKit

#if canImport(ActivityKit) && os(iOS)
import ActivityKit

struct DeploymentAttributes: ActivityAttributes {
	struct ContentState: Codable & Hashable {
		let deploymentState: VercelDeployment.State
		let progress: Int?
		let errorMessage: String?

		enum CodingKeys: String, CodingKey {
			case status, progress, errorMessage
		}

		init(deploymentState: VercelDeployment.State, progress: Int? = nil, errorMessage: String? = nil) {
			self.deploymentState = deploymentState
			self.progress = progress
			self.errorMessage = errorMessage
		}

		init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			let statusString = try container.decode(String.self, forKey: .status)
			self.deploymentState = VercelDeployment.State(rawValue: statusString) ?? .building
			self.progress = try container.decodeIfPresent(Int.self, forKey: .progress)
			self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
		}

		func encode(to encoder: Encoder) throws {
			var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(deploymentState.rawValue, forKey: .status)
			try container.encodeIfPresent(progress, forKey: .progress)
			try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
		}
	}

	/// Simple string attributes that match server encoding for push-to-start
	let deploymentId: String
	let projectName: String
	let commitMessage: String?
}

struct DeploymentLiveActivity: Widget {
	var body: some WidgetConfiguration {
		ActivityConfiguration(for: DeploymentAttributes.self) { context in
			// Lock screen/banner UI
			HStack(spacing: 12) {
				DeploymentStateIndicator(state: context.state.deploymentState, style: .compact)
					.font(.title2)

				VStack(alignment: .leading, spacing: 4) {
					Text(context.attributes.projectName)
						.font(.headline)
						.lineLimit(1)

					HStack(spacing: 4) {
						DeploymentStateIndicator(state: context.state.deploymentState)
							.font(.subheadline)

						if let message = context.attributes.commitMessage {
							Text("·")
								.foregroundStyle(.secondary)
							Text(message)
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
						Text(context.attributes.projectName)
							.font(.headline)
							.lineLimit(1)

						if let message = context.attributes.commitMessage {
							Text(message)
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
#endif
