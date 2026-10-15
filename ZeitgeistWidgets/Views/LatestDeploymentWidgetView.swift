//
//  LatestDeploymentWidgetView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//  Updated by Brad Bergeron on 22/11/2023.
//

import SwiftUI
import WidgetKit

// MARK: - LatestDeploymentWidgetView

struct LatestDeploymentWidgetView: View {
	// MARK: Internal

	let config: LatestDeploymentEntry

	var body: some View {
		Group {
			switch widgetFamily {
			case .systemSmall, .systemMedium:
				LatestDeploymentSystemView(
					deployment: config.deployment,
					account: config.account,
					project: config.project
				)
			case .systemLarge, .systemExtraLarge:
				// These sizes are unsupported by the widget. See ``LatestDeploymentWidget`` for configuration.
				Color.clear
			case .accessoryCircular:
				LatestDeploymentCircularAccessoryView(deployment: config.deployment)
			case .accessoryRectangular, .accessoryInline:
				LatestDeploymentAccessoryView(deployment: config.deployment)
			@unknown default:
				Color.clear
			}
		}
		.widgetURL(deepLinkURL)
		.containerBackground(.background, for: .widget)
	}

	// MARK: Private

	@Environment(\.widgetFamily) private var widgetFamily

	private var deepLinkURL: URL {
		let accountId = config.account.identifier ?? "0"
		let deploymentId = config.deployment?.id ?? "0"
		let projectId = config.deployment?.projectId ?? ""
		return URL(string: "zeitgeist://deployment/\(accountId)/\(deploymentId)/\(projectId)")!
	}
}

// MARK: - LatestDeploymentSystemView

private struct LatestDeploymentSystemView: View {
	let deployment: VercelDeployment?
	let account: WidgetAccount
	let project: WidgetProject?

	private var hasProject: Bool {
		project?.identifier != nil
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 2) {
			if let deployment {
				HStack {
					DeploymentStateIndicator(state: deployment.state)
					Spacer()
					if deployment.target == .production {
						Image(systemName: "theatermasks")
							.foregroundStyle(.tint)
							.symbolVariant(.fill)
							.imageScale(.small)
							.widgetAccentable()
					}
				}
				.font(.caption.bold())
				.padding(.bottom, 2)

				Text(deployment.deploymentCause.description)
					.font(.subheadline)
					.fontWeight(.semibold)
					.lineLimit(3)
					.allowsTightening(true)
					.layoutPriority(1)

				Group {
					Text(deployment.created, style: .relative)
						.foregroundStyle(.secondary)

					if !hasProject {
						Text(deployment.project)
							.lineLimit(1)
							.foregroundStyle(.secondary)
					}
				}
			} else {
				PlaceholderView(forRole: .NoDeployments, alignment: .leading)
					.font(.footnote)
			}

			Spacer(minLength: 0)

			Group {
				WidgetLabel(label: account.displayString, iconName: account.identifier?.isTeam == true ? "person.2" : "person")
					.symbolVariant(account.identifier == nil ? .none : .fill)

				if let project,
				   project.identifier != nil
				{
					WidgetLabel(label: project.displayString, iconName: "folder")
				}
			}
			.foregroundStyle(.secondary)
			.imageScale(.small)
			.lineLimit(1)
		}
		.multilineTextAlignment(.leading)
		.frame(maxWidth: .infinity, alignment: .leading)
		.font(.footnote)
		.foregroundStyle(.primary)
		.symbolRenderingMode(.hierarchical)
		.tint(.indigo)
	}
}

// MARK: - LatestDeploymentCircularAccessoryView

private struct LatestDeploymentCircularAccessoryView: View {
	let deployment: VercelDeployment?

	var body: some View {
		ZStack {
			AccessoryWidgetBackground()

			Label {
				if let deployment {
					let stateText = Text(deployment.state.description)
					Text("Latest deployment for \(deployment.project): \(stateText)")
				} else {
					Text("No recent deployment")
				}
			} icon: {
				Image(systemName: deployment?.state.imageName ?? "arrowtriangle.up.circle")
					.imageScale(.large)
					.font(.largeTitle)
			}
			.labelStyle(.iconOnly)
		}
	}
}

// MARK: - LatestDeploymentAccessoryView

private struct LatestDeploymentAccessoryView: View {
	let deployment: VercelDeployment?

	var body: some View {
		VStack(alignment: .leading) {
			if let deployment {
				Label {
					Text(deployment.project)
						.font(.headline)
				} icon: {
					DeploymentStateIndicator(state: deployment.state, style: .compact)
						.symbolRenderingMode(.monochrome)
				}

				Text(deployment.deploymentCause.description)
					.lineLimit(2)
				Text(deployment.created, style: .relative)
					.foregroundStyle(.secondary)
			} else {
				Group {
					HStack {
						DeploymentStateIndicator(state: .queued, style: .compact)
						Text("Loading...")
					}
					Text("Waiting for data")
						.foregroundStyle(.secondary)
					Text(.now, style: .relative)
						.foregroundStyle(.tertiary)
				}
				.redacted(reason: .placeholder)
			}
		}
		.allowsTightening(true)
		.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
	}
}

#if DEBUG

	struct LatestDeploymentWidgetView_Previews: PreviewProvider {
		// MARK: Internal

		static var previews: some View {
			LatestDeploymentWidgetView(config: .mockNoAccount)
				.previewContext(WidgetPreviewContext(family: widgetFamily))
				.previewDisplayName("No Account")

			LatestDeploymentWidgetView(config: .mockExample)
				.previewContext(WidgetPreviewContext(family: widgetFamily))
				.previewDisplayName("Example")
		}

		// MARK: Private

		@Environment(\.widgetFamily) private static var widgetFamily
	}

#endif
