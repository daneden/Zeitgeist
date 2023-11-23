//
//  WidgetPaddingViewModifier.swift
//  Zeitgeist
//
//  Created by Brad Bergeron on 23/11/2023.
//

import SwiftUI

// MARK: - View + widgetPadding

extension View {
	func widgetPadding() -> some View {
		modifier(WidgetPaddingViewModifier())
	}

	func widgetBackgroundRemovedPadding(_ edges: Edge.Set = .all, _ length: CGFloat? = nil) -> some View {
		modifier(WidgetBackgroundRemovedPaddingViewModifier(edges: edges, length: length))
	}

	func widgetBackgroundRemovedPadding(_ length: CGFloat) -> some View {
		widgetBackgroundRemovedPadding(.all, length)
	}
}

// MARK: - WidgetPaddingViewModifier

private struct WidgetPaddingViewModifier: ViewModifier {
	
	// MARK: Internal

	func body(content: Content) -> some View {
		if #available(iOSApplicationExtension 17.0, *) {
			if showsWidgetContainerBackground {
				content.padding(widgetContentMargins)
			} else {
				content
			}
		} else {
			content.padding()
		}
	}

	// MARK: Private

	@Environment(\.showsWidgetContainerBackground) private var showsWidgetContainerBackground

	@available(iOSApplicationExtension 17.0, *)
	private var widgetContentMargins: EdgeInsets {
		@Environment(\.widgetContentMargins) var contentMargins
		return contentMargins
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
