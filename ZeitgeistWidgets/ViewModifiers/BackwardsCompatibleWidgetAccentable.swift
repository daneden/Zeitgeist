//
//  BackwardsCompatibleWidgetAccentable.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 17/09/2024.
//

import SwiftUI

struct BackwardsCompatibleWidgetAccentable: ViewModifier {
	func body(content: Content) -> some View {
		if #available(iOS 16, macOS 14, *) {
			return content.widgetAccentable()
		} else {
			return content
		}
	}
}

extension View {
	func backwardsCompatibleWidgetAccentable() -> some View {
		self.modifier(BackwardsCompatibleWidgetAccentable())
	}
}
