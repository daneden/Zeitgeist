//
//  TokenStore.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/01/2026.
//

import Foundation

// MARK: - TokenStore Protocol

/// Protocol for secure token storage operations.
/// Enables dependency injection and testability for authentication flows.
protocol TokenStore: Sendable {
	/// Retrieves the token for a given account ID
	func getToken(for accountId: String) -> String?

	/// Stores a token for a given account ID
	func setToken(_ token: String, for accountId: String)

	/// Removes the token for a given account ID
	func removeToken(for accountId: String)

	/// Checks if a token exists for a given account ID
	func hasToken(for accountId: String) -> Bool
}

extension TokenStore {
	func hasToken(for accountId: String) -> Bool {
		getToken(for: accountId) != nil
	}
}

// MARK: - KeychainTokenStore

/// Default implementation using the system Keychain via KeychainItem.
/// Tokens are stored with iCloud sync enabled for cross-device availability.
struct KeychainTokenStore: TokenStore {
	func getToken(for accountId: String) -> String? {
		KeychainItem(account: accountId).wrappedValue
	}

	func setToken(_ token: String, for accountId: String) {
		KeychainItem(account: accountId).wrappedValue = token
	}

	func removeToken(for accountId: String) {
		KeychainItem(account: accountId).wrappedValue = nil
	}
}

// MARK: - MockTokenStore (for testing)

#if DEBUG
/// In-memory token store for unit testing.
final class MockTokenStore: TokenStore, @unchecked Sendable {
	private var tokens: [String: String] = [:]
	private let lock = NSLock()

	func getToken(for accountId: String) -> String? {
		lock.lock()
		defer { lock.unlock() }
		return tokens[accountId]
	}

	func setToken(_ token: String, for accountId: String) {
		lock.lock()
		defer { lock.unlock() }
		tokens[accountId] = token
	}

	func removeToken(for accountId: String) {
		lock.lock()
		defer { lock.unlock() }
		tokens.removeValue(forKey: accountId)
	}

	/// Clears all stored tokens (useful for test setup/teardown)
	func clearAll() {
		lock.lock()
		defer { lock.unlock() }
		tokens.removeAll()
	}
}
#endif
