//
//  LatestDeploymentWidgetView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//  Updated by Brad Bergeron on 22/11/2023.
//

import SwiftUI
import WidgetKit

struct LatestDeploymentWidgetView: View {
	@Environment(\.widgetFamily) var widgetFamily
	var config: LatestDeploymentEntry

	var hasProject: Bool {
		config.project?.identifier != nil
	}

	var isAccessoryView: Bool {
		if #available(iOSApplicationExtension 16.0, *) {
			return widgetFamily == .accessoryRectangular || widgetFamily == .accessoryCircular || widgetFamily == .accessoryInline
		} else {
			return false
		}
	}

	var body: some View {
		if isAccessoryView {
			switch widgetFamily {
			case .accessoryCircular:
				Image(systemName: config.deployment?.state.imageName ?? "arrowtriangle.up.circle")
					.font(.largeTitle)
					.imageScale(.large)
			default:
				VStack(alignment: .leading) {
					if let deployment = config.deployment {
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
		} else {
			Link(destination: URL(string: "zeitgeist://open/\(config.account.identifier ?? "0")/\(config.deployment?.id ?? "0")")!) {
				VStack(alignment: .leading, spacing: 4) {
					if let deployment = config.deployment {
						HStack {
							DeploymentStateIndicator(state: deployment.state)
							Spacer()
							if deployment.target == .production {
								Image(systemName: "theatermasks")
									.foregroundStyle(.tint)
									.symbolVariant(.fill)
									.imageScale(.small)
							}
						}
						.font(.caption.bold())
						.padding(.bottom, 2)

						Text(deployment.deploymentCause.description)
							.font(.subheadline)
							.fontWeight(.bold)
							.lineLimit(3)

						Text(deployment.created, style: .relative)
							.foregroundStyle(.secondary)

						if !hasProject {
							Text(deployment.project)
								.lineLimit(1)
								.foregroundStyle(.secondary)
						}
					} else {
						PlaceholderView(forRole: .NoDeployments, alignment: .leading)
							.font(.footnote)
					}

					Spacer()


					Group {
						WidgetLabel(label: config.account.displayString, iconName: config.account.identifier?.isTeam == true ? "person.2" : "person")
							.symbolVariant(config.account.identifier == nil ? .none : .fill)

						if let project = config.project,
							 project.identifier != nil {
							WidgetLabel(label: project.displayString, iconName: "folder")
						}
					}
					.foregroundStyle(.secondary)
					.imageScale(.small)
					.lineLimit(1)
				}
				.multilineTextAlignment(.leading)
				.frame(maxWidth: .infinity, alignment: .leading)
			}
			.font(.footnote)
			.foregroundStyle(.primary)
			.padding()
			.background(.background)
			.symbolRenderingMode(.hierarchical)
			.tint(.indigo)
		}
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
