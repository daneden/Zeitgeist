//
//  View+backportCircleSymbolVariant.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 26/08/2025.
//

import SwiftUI

extension View {
	func backportCircleSymbolVariant() -> some View {
		if #available(iOS 26, macOS 26, visionOS 26, *) {
			return self
		} else {
			return self.symbolVariant(.circle)
		}
	}
}
