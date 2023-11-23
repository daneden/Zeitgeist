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
	var label: String
	var iconName: String

	var body: some View {
		Label(label, systemImage: iconName)
			.labelStyle(WidgetLabelStyle())
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
		.padding(.horizontal, showsContainerBackground ? 4 : 0)
		.padding(.vertical, showsContainerBackground ? 2 : 0)
		.background(showsContainerBackground ? AnyShapeStyle(.thickMaterial) : AnyShapeStyle(.clear))
		.clipShape(ContainerRelativeShape())
	}

	// MARK: Private

	@Environment(\.showsWidgetContainerBackground) private var showsContainerBackground
}
