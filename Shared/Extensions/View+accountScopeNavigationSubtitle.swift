//
//  View+accountScopeNavigationSubtitle.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 16/01/2026.
//

import SwiftUI
import Suite

extension View {
	func backportNavigationSubtitle(_ subtitle: String?) -> some View {
		modify {
			if #available(iOS 26, macOS 11, *) {
				if let subtitle {
					$0.navigationSubtitle(subtitle)
				} else {
					$0
				}
			} else {
				$0
			}
		}
	}
}
