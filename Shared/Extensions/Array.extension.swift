//
//  Array.extension.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

extension Array where Element: Hashable {
	mutating func toggleElement(_ element: Element, inArray: Bool) {
		if inArray {
			append(element)
		} else {
			removeAll { $0 == element }
		}
	}

	/// Projects membership of an element as a settable Bool, so SwiftUI
	/// bindings can go through a KeyPath subscript (e.g.
	/// `$ids[contains: id]`) instead of allocating get/set closures on
	/// every body evaluation.
	subscript(contains element: Element) -> Bool {
		get { contains(element) }
		set { toggleElement(element, inArray: newValue) }
	}
}

extension Array: @retroactive RawRepresentable where Element: Codable {
	public init?(rawValue: String) {
		guard let data = rawValue.data(using: .utf8),
		      let result = try? JSONDecoder().decode([Element].self, from: data)
		else {
			return nil
		}
		self = result
	}

	public var rawValue: String {
		guard let data = try? JSONEncoder().encode(self),
		      let result = String(data: data, encoding: .utf8)
		else {
			return "[]"
		}
		return result
	}
}
