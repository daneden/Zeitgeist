//
//  KeychainItem.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//  swiftlint:disable all

import Foundation
import Security

private func throwIfNotZero(_ status: OSStatus) throws {
	guard status != 0 else { return }
	throw KeychainError.keychainError(status: status)
}

public enum KeychainError: Error {
	case invalidData
	case keychainError(status: OSStatus)
}

extension Dictionary {
	func adding(key: Key, value: Value) -> Dictionary {
		var copy = self
		copy[key] = value
		return copy
	}
}

@propertyWrapper
public final class KeychainItem {
	private let account: String
	private let accessGroup: String?

	public init(account: String) {
		self.account = account
		accessGroup = nil
	}

	public init(account: String, accessGroup: String) {
		self.account = account
		self.accessGroup = accessGroup
	}

	/// Base dictionary for queries - does NOT include accessibility attribute
	/// to allow finding tokens stored with any accessibility level (for migration).
	private var queryBaseDictionary: [String: AnyObject] {
		let base: [String: AnyObject] = [
			kSecClass as String: kSecClassGenericPassword,
			kSecAttrAccount as String: account as AnyObject,
			kSecAttrSynchronizable as String: kCFBooleanTrue!,
		]

		return accessGroup == nil
			? base
			: base.adding(key: kSecAttrAccessGroup as String, value: accessGroup as AnyObject)
	}

	/// Dictionary for adding/updating items - includes the desired accessibility attribute.
	private var storageDictionary: [String: AnyObject] {
		queryBaseDictionary.adding(
			key: kSecAttrAccessible as String,
			value: kSecAttrAccessibleAfterFirstUnlock
		)
	}

	/// Query dictionary without accessibility - finds items regardless of how they were stored.
	private var query: [String: AnyObject] {
		return queryBaseDictionary.adding(key: kSecMatchLimit as String, value: kSecMatchLimitOne)
	}

	/// Query dictionary with the correct accessibility - for checking if migration is needed.
	private var migratedQuery: [String: AnyObject] {
		return storageDictionary.adding(key: kSecMatchLimit as String, value: kSecMatchLimitOne)
	}

	public var wrappedValue: String? {
		get {
			guard let value = try? read() else { return nil }
			// Attempt migration if needed (will silently fail if device is locked)
			migrateIfNeeded(value: value)
			return value
		}
		set {
			if let v = newValue {
				// Always delete and re-add to ensure correct accessibility attribute.
				// Both operations use try? since they may fail if device is locked
				// (though setting tokens typically only happens when device is unlocked).
				try? delete()
				try? add(v)
			} else {
				try? delete()
			}
		}
	}

	private func delete() throws {
		// SecItemDelete seems to fail with errSecItemNotFound if the item does not exist in the keychain. Is this expected behavior?
		// Use queryBaseDictionary to delete items regardless of their accessibility attribute
		let status = SecItemDelete(queryBaseDictionary as CFDictionary)
		guard status != errSecItemNotFound else { return }
		try throwIfNotZero(status)
	}

	private func read() throws -> String? {
		let query = self.query.adding(key: kSecReturnData as String, value: true as AnyObject)
		var result: AnyObject?
		let status = SecItemCopyMatching(query as CFDictionary, &result)
		guard status != errSecItemNotFound else { return nil }
		try throwIfNotZero(status)
		guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
			throw KeychainError.invalidData
		}
		return string
	}

	/// Checks if the item is already stored with the correct accessibility attribute.
	private func isAlreadyMigrated() -> Bool {
		let query = migratedQuery.adding(key: kSecReturnData as String, value: false as AnyObject)
		let status = SecItemCopyMatching(query as CFDictionary, nil)
		return status == errSecSuccess
	}

	/// Migrates a token to use kSecAttrAccessibleAfterFirstUnlock if needed.
	/// This ensures widgets can access the token when the device is locked.
	private func migrateIfNeeded(value: String) {
		guard !isAlreadyMigrated() else { return }
		// Delete the old item and re-add with correct accessibility
		// This may fail if device is locked, but that's okay - we'll try again next time
		try? delete()
		try? add(value)
	}

	private func add(_ secret: String) throws {
		// Use storageDictionary to set the correct accessibility attribute for new items
		let dictionary = storageDictionary.adding(key: kSecValueData as String, value: secret.data(using: .utf8)! as AnyObject)
		try throwIfNotZero(SecItemAdd(dictionary as CFDictionary, nil))
	}
}
