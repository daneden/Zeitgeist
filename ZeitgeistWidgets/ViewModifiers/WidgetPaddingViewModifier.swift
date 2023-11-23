//
//  WidgetPaddingViewModifier.swift
//  Zeitgeist
//
//  Created by Brad Bergeron on 23/11/2023.
//

import SwiftUI

// MARK: - View + widgetPadding

extension View {
	/// Add padding to this widget view.
	///
	/// For iOS 16 and below, the default system padding is applied.
	///
	/// On iOS 17+, this modifier has no effect, as the standard widget content margins are used.
	///
	/// - Returns: The modified view.
	func widgetPadding() -> some View {
		modifier(WidgetPaddingViewModifier())
	}
	
	/// Apply padding to this widget view when its container background has been removed.
	///
	/// For iOS 16 and below, this modifier has no effect.
	///
	/// - Parameters:
	///   - edges: The set of edges to pad for this view. The default is ``Edge.Set.all``.
	///   - length: An amount, given in points, to pad this view on the specified edges. If you set the value to `nil`,
	///     SwiftUI uses a platform-specific default amount. The default value of this parameter is `nil`.
	/// - Returns: A view that's padded by the specified amount on the specified edges.
	func widgetBackgroundRemovedPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
		modifier(WidgetBackgroundRemovedPaddingViewModifier(edges: edges, length: length))
	}
	
	/// Apply padding to this widget view when its container background has been removed.
	///
	/// For iOS 16 and below, this modifier has no effect.
	///
	/// - Parameter length: The amount, given in points, to pad this view on all edges.
	/// - Returns: A view that's padded by the amount you specify.
	func widgetBackgroundRemovedPadding(_ length: CGFloat) -> some View {
		widgetBackgroundRemovedPadding(.all, length)
	}
}

// MARK: - WidgetPaddingViewModifier

private struct WidgetPaddingViewModifier: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOSApplicationExtension 17.0, *) {
			content
		} else {
			content.padding()
		}
	}
}

// MARK: - WidgetBackgroundRemovedPaddingViewModifier

private struct WidgetBackgroundRemovedPaddingViewModifier: ViewModifier {

	// MARK: Internal

	let edges: Edge.Set
	let length: CGFloat?

	func body(content: Content) -> some View {
		if #available(iOSApplicationExtension 17.0, *), !showsWidgetContainerBackground {
			content.padding(edges, length)
		} else {
			content
		}
	}

	// MARK: Private

	@Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

}
