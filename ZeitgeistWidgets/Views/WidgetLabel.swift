//
//  WidgetLabel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//  Updated by Brad Bergeron on 22/11/2023.
//

import SwiftUI

// MARK: - WidgetLabel

struct WidgetLabel: View {
	let label: String
	let iconName: String

	var body: some View {
		Label(label, systemImage: iconName)
			.labelStyle(WidgetLabelStyle())
			.widgetAccentable()
	}
}

// MARK: - WidgetLabelStyle

private struct WidgetLabelStyle: LabelStyle {

	// MARK: Internal

	func makeBody(configuration: Configuration) -> some View {
		HStack(alignment: .center, spacing: 4) {
			configuration.icon
			configuration.title
		}
		.font(.system(size: 13, weight: .medium))
		.padding(.horizontal, showsWidgetContainerBackground ? 4 : 0)
		.padding(.vertical, showsWidgetContainerBackground ? 2 : 0)
		.background(showsWidgetContainerBackground ? AnyShapeStyle(.quaternary.opacity(0.5)) : AnyShapeStyle(.clear))
		.clipShape(ContainerRelativeShape())
	}

	// MARK: Private

	@Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

}
