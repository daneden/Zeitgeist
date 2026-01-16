//
//  View+avatarMask.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/01/2026.
//

import SwiftUI

struct AvatarMaskViewModifier: ViewModifier {
	@Environment(\.colorScheme) private var colorScheme
	
	var blendMode: BlendMode {
		switch colorScheme {
		case .dark: return .plusLighter
		case .light: return .plusDarker
		@unknown default: return .normal
		}
	}
	
	func body(content: Content) -> some View {
		content
			.clipShape(.circle)
			.overlay {
				Circle()
					.fill(.clear)
					.strokeBorder(.tertiary, lineWidth: 0.5)
					.blendMode(blendMode)
			}
	}
}

extension View {
	func avatarMask() -> some View {
		modifier(AvatarMaskViewModifier())
	}
}
