//
//  RecentDeploymentsWidgetView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//  Updated by Brad Bergeron on 22/11/2023.
//

import SwiftUI
import WidgetKit

// MARK: - RecentDeploymentsWidgetView

struct RecentDeploymentsWidgetView: View {

	// MARK: Internal

	let config: RecentDeploymentsEntry

	var body: some View {
		Group {
			switch widgetFamily {
			case .systemSmall, .systemMedium:
				/// These sizes are unsupported by the widget. See ``RecentDeploymentsWidget`` for configuration.
				Color.clear
			case .systemLarge, .systemExtraLarge:
				systemView
			case .accessoryCircular, .accessoryRectangular, .accessoryInline:
				/// These sizes are unsupported by the widget. See ``RecentDeploymentsWidget`` for configuration.
				Color.clear
			@unknown default:
				Color.clear
			}
		}
	}

	// MARK: Private

	@Environment(\.dynamicTypeSize) private var dynamicTypeSize
	@Environment(\.widgetFamily) private var widgetFamily

	private var numberOfDeployments: Int {
		switch dynamicTypeSize {
		case .xSmall,
				.small,
				.medium,
				.large:
			return 5
		case .accessibility3,
				.accessibility4,
				.accessibility5:
			return 3
		default: 
			return 4
		}
	}

	private var systemView: some View {
		VStack(alignment: .leading) {
			Label("Recent Deployments", systemImage: "clock")
				.font(.footnote.bold())

			Spacer(minLength: 0)

			if let deployments = config.deployments?.prefix(numberOfDeployments) {
				ForEach(deployments) { deployment in
					Divider()
					Spacer(minLength: 0)
					RecentDeploymentsListRowView(
						accountId: config.account.identifier ?? "0",
						deployment: deployment,
						project: config.project
					)
					Spacer(minLength: 0)
				}
			} else {
				VStack(alignment: .center) {
					Spacer(minLength: 0)
					PlaceholderView(forRole: .NoDeployments)
						.frame(maxWidth: .infinity)
						.font(.footnote)
					Spacer(minLength: 0)
				}
			}

			Spacer(minLength: 0)

			HStack {
				WidgetLabel(label: config.account.displayString, iconName: config.account.identifier?.isTeam == true ? "person.2" : "person")
					.symbolVariant(config.account.identifier == nil ? .none : .fill)

				Spacer()

				if let project = config.project,
					 project.identifier != nil {
					WidgetLabel(label: project.displayString, iconName: "folder")
				}
			}
			.font(.caption)
			.foregroundStyle(.secondary)
			.lineLimit(1)
		}
	}

}

// MARK: - RecentDeploymentsListRowView

struct RecentDeploymentsListRowView: View {

	// MARK: Internal

	let accountId: String
	let deployment: VercelDeployment
	let project: WidgetProject?

	var body: some View {
		Link(destination: URL(string: "zeitgeist://open/\(accountId)/\(deployment.id)")!) {
			Label {
				VStack(alignment: .leading) {
					Text(deployment.deploymentCause.description)
						.fontWeight(.bold)
						.foregroundStyle(.primary)

					HStack {
						if deployment.target == .production {
							Image(systemName: "theatermasks")
								.foregroundStyle(.tint)
								.symbolRenderingMode(.hierarchical)
								.symbolVariant(.fill)
								.imageScale(.small)
								.widgetAccentable()
						}

						if project?.identifier == nil {
							HStack {
								Text(deployment.project)
								Text(verbatim: "•")
								Text(deployment.created, style: .relative)
							}
						} else {
							Text(deployment.created, style: .relative)
						}
					}
				}
				.foregroundStyle(.secondary)
				.lineLimit(1)
				.imageScale(dynamicTypeSize.isAccessibilitySize ? .small : .medium)
			} icon: {
				DeploymentStateIndicator(state: deployment.state, style: .compact)
			}
			.font(.subheadline)
			.tint(.indigo)
		}
	}

	// MARK: Private

	@Environment(\.dynamicTypeSize) private var dynamicTypeSize

}

#if DEBUG

struct RecentDeploymentsWidgetView_Previews: PreviewProvider {

	// MARK: Internal

	static var previews: some View {
		RecentDeploymentsWidgetView(config: .mockNoAccount)
			.previewContext(WidgetPreviewContext(family: widgetFamily))
			.previewDisplayName("No Account")

		RecentDeploymentsWidgetView(config: .mockExample)
			.previewContext(WidgetPreviewContext(family: widgetFamily))
			.previewDisplayName("Example")
	}

	// MARK: Private

	@Environment(\.widgetFamily) private static var widgetFamily

}

#endif
