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
	
	/// Apply padding to this widget view when it's being displayed in StandBy mode.
	///
	/// For iOS 16 and below, this modifier has no effect.
	///
	/// - Parameters:
	///   - edges: The set of edges to pad for this view. The default is ``Edge.Set.all``.
	///   - length: An amount, given in points, to pad this view on the specified edges. If you set the value to `nil`,
	///     SwiftUI uses a platform-specific default amount. The default value of this parameter is `nil`.
	/// - Returns: A view that's padded by the specified amount on the specified edges.
	func widgetStandByModePadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
		modifier(WidgetStandByModePaddingViewModifier(edges: edges, length: length))
	}
	
	/// Apply padding to this widget view when it's being displayed in StandBy mode.
	///
	/// For iOS 16 and below, this modifier has no effect.
	///
	/// - Parameter length: The amount, given in points, to pad this view on all edges.
	/// - Returns: A view that's padded by the amount you specify.
	func widgetStandByModePadding(_ length: CGFloat) -> some View {
		widgetStandByModePadding(.all, length)
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

// MARK: - WidgetStandByModePaddingViewModifier

private struct WidgetStandByModePaddingViewModifier: ViewModifier {

	// MARK: Internal

	let edges: Edge.Set
	let length: CGFloat?

	func body(content: Content) -> some View {
		if 
			#available(iOSApplicationExtension 17.0, *),
			isPhone,
			!showsWidgetContainerBackground
		{
			content.padding(edges, length)
		} else {
			content
		}
	}

	// MARK: Private

	private let isPhone = UIDevice.current.userInterfaceIdiom == .phone
	@Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

}
