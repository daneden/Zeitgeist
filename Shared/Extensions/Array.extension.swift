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

	func contains(_ element: Element) -> Bool {
		contains { $0 == element }
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
