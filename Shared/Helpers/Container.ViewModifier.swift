//
//  Container.ViewModifier.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2021.
//

import Foundation
import SwiftUI

struct Container: ViewModifier {
	@ScaledMetric var paddingAmount: CGFloat = 24
	func body(content: Content) -> some View {
		#if os(macOS)
			ScrollView {
				content
					.padding(paddingAmount)
			}
		#else
			content
		#endif
	}
}

extension View {
	func makeContainer() -> some View {
		modifier(Container())
	}
}
