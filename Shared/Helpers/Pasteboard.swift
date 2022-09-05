//
//  Pasteboard.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 07/08/2022.
//

import Foundation

#if os(macOS)
	import AppKit
#elseif os(iOS)
	import UIKit
#endif

struct Pasteboard {
	static func setString(_ value: String?) {
		#if os(macOS)
			guard let value = value else {
				return
			}

			NSPasteboard.general.setString(value, forType: .string)
		#elseif os(iOS)
			UIPasteboard.general.string = value
		#endif
	}
}
