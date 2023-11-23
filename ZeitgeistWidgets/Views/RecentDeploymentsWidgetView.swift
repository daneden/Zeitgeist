//
//  RecentDeploymentsWidgetView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//  Updated by Brad Bergeron on 22/11/2023.
//

import SwiftUI
import WidgetKit

struct RecentDeploymentsWidgetView: View {
	@Environment(\.sizeCategory) var sizeCategory
	var config: RecentDeploymentsEntry

	var accountLabel: some View {
		Label {
			Text(config.account.displayString)
		} icon: {
			Image(systemName: "person")
				.symbolVariant(config.account.identifier == nil ? .none : .fill)
		}
		.foregroundStyle(.secondary)
	}

	var widgetTitle: some View {
		Label("Recent Deployments", systemImage: "clock")
			.font(.footnote.bold())
	}

	var numberOfDeployments: Int {
		switch sizeCategory {
		case .extraSmall,
				.small,
				.medium,
				.large:
			return 5
		case .accessibilityExtraLarge,
				.accessibilityExtraExtraLarge,
				.accessibilityExtraExtraExtraLarge:
			return 3
		default: return 4
		}
	}

	var body: some View {
		VStack(alignment: .leading) {
			widgetTitle

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
		.padding()
		.background(.background)
	}
}

struct RecentDeploymentsListRowView: View {
	@Environment(\.dynamicTypeSize) var dynamicTypeSize
	var accountId: String
	var deployment: VercelDeployment
	var project: WidgetProject?

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
