//
//  KeyedDecodingContainer+Fallback.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/01/2026.
//

import Foundation

extension KeyedDecodingContainer {
	/// Decodes a value by trying multiple keys in order until one succeeds.
	/// - Parameters:
	///   - type: The type to decode
	///   - keys: The keys to try, in order of preference
	/// - Returns: The decoded value
	/// - Throws: DecodingError if no key contains a valid value
	func decode<T: Decodable>(_ type: T.Type, forKeys keys: Key...) throws -> T {
		try decode(type, forKeys: keys)
	}

	/// Decodes a value by trying multiple keys in order until one succeeds.
	/// - Parameters:
	///   - type: The type to decode
	///   - keys: The keys to try, in order of preference
	/// - Returns: The decoded value
	/// - Throws: DecodingError if no key contains a valid value
	func decode<T: Decodable>(_ type: T.Type, forKeys keys: [Key]) throws -> T {
		guard let lastKey = keys.last else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(
					codingPath: codingPath,
					debugDescription: "No keys provided for decoding"
				)
			)
		}

		for key in keys.dropLast() {
			if let value = try? decode(T.self, forKey: key) {
				return value
			}
		}

		return try decode(T.self, forKey: lastKey)
	}

	/// Decodes an optional value by trying multiple keys in order until one succeeds.
	/// - Parameters:
	///   - type: The type to decode
	///   - keys: The keys to try, in order of preference
	/// - Returns: The decoded value, or nil if no key contains a value
	func decodeIfPresent<T: Decodable>(_ type: T.Type, forKeys keys: Key...) -> T? {
		decodeIfPresent(type, forKeys: keys)
	}

	/// Decodes an optional value by trying multiple keys in order until one succeeds.
	/// - Parameters:
	///   - type: The type to decode
	///   - keys: The keys to try, in order of preference
	/// - Returns: The decoded value, or nil if no key contains a value
	func decodeIfPresent<T: Decodable>(_ type: T.Type, forKeys keys: [Key]) -> T? {
		for key in keys {
			if let value = try? decodeIfPresent(T.self, forKey: key) {
				return value
			}
		}
		return nil
	}
}
