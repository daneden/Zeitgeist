//
//  WidgetBackgroundViewModifier.swift
//  Zeitgeist
//
//  Created by Brad Bergeron on 22/11/2023.
//

import SwiftUI

// MARK: - View + widgetBackground

extension View {
	/// Apply the specified ``ShapeStyle`` to the background of this widget view.
	///
	/// On iOS 17+, this modifier utilizes the new ``View.containerBackground(_:for:)`` view modifier to set a background
	/// that is removable depending on the widget's location.
	///
	/// For iOS 16 and below, this modifier has no effect.
	///
	/// - Parameter shape: The shape style to use as the container background.
	/// - Returns: A view with the specified style drawn behind it.
	func widgetBackground(_ shape: some ShapeStyle = .clear) -> some View {
		modifier(WidgetBackgroundViewModifier(shape: shape))
	}
	
	/// Apply the specified content to the background of this widget view.
	///
	/// On iOS 17+, this modifier utilizes the new ``View.containerBackground(for:alignment:content:)`` view modifier
	/// to set a background that is removable depending on the widget's location.
	///
	/// For iOS 16 and below, this modifier has no effect.
	///
	/// - Parameters:
	///   - alignment: The alignment that the modifier uses to position the implicit ``ZStack`` that groups
	///     the background views. The default is ``Alignment/center``.
	///   - content: The view to use as the background of the container.
	/// - Returns: A view with the specified content drawn behind it.
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
		if #available(iOSApplicationExtension 17.0, *) {
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
