//
//  WidgetBackgroundViewModifier.swift
//  Zeitgeist
//
//  Created by Brad Bergeron on 22/11/2023.
//

import SwiftUI

// MARK: - View + widgetBackground

extension View {
	func widgetBackground(_ shape: some ShapeStyle = .clear) -> some View {
		modifier(WidgetBackgroundViewModifier(shape: shape))
	}

	func widgetBackground(alignment: Alignment = .center, content: @escaping () -> some View) -> some View {
		modifier(WidgetBackgroundViewModifier(alignment: alignment, background: content))
	}
}

// MARK: - WidgetBackgroundViewModifier

private struct WidgetBackgroundViewModifier<Shape: ShapeStyle, Background: View>: ViewModifier {

	// MARK: Lifecycle

	init(shape: Shape) where Background == EmptyView {
		configuration = .shape(shape)
	}

	init(alignment: Alignment, background: @escaping () -> Background) where Shape == Color {
		configuration = .view(alignment, background)
	}

	// MARK: Internal

	func body(content: Content) -> some View {
		if #available(iOS 17.0, *) {
			switch configuration {
			case .shape(let style):
				content.containerBackground(style, for: .widget)
			case .view(let alignment, let background):
				content.containerBackground(for: .widget, alignment: alignment, content: background)
			}
		} else {
			content
		}
	}

	// MARK: Private

	private enum Configuration {
		case shape(Shape)
		case view(Alignment, () -> Background)
	}

	private let configuration: Configuration

}
