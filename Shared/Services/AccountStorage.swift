//
//  AccountStorage.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/01/2026.
//

import Foundation

// MARK: - AccountStorage Protocol

/// Protocol for persisting account metadata.
/// Enables dependency injection and testability for account management.
protocol AccountStorage: Sendable {
	/// Loads all stored accounts
	func loadAccounts() -> [VercelAccount]

	/// Saves the account list, replacing any existing data
	func saveAccounts(_ accounts: [VercelAccount])
}

// MARK: - UserDefaultsAccountStorage

/// Default implementation using UserDefaults via the app group container.
/// This matches the existing Preferences.accounts storage mechanism.
struct UserDefaultsAccountStorage: AccountStorage {
	private let store: UserDefaults
	private let key: String

	init(store: UserDefaults = Preferences.store,
	     key: String = Preferences.Keys.authenticatedAccounts.rawValue) {
		self.store = store
		self.key = key
	}

	func loadAccounts() -> [VercelAccount] {
		// @AppStorage uses RawRepresentable which stores arrays as JSON strings, not Data
		guard let jsonString = store.string(forKey: key),
		      let data = jsonString.data(using: .utf8) else {
			return []
		}

		do {
			return try JSONDecoder().decode([VercelAccount].self, from: data)
		} catch {
			print("Failed to decode accounts: \(error)")
			return []
		}
	}

	func saveAccounts(_ accounts: [VercelAccount]) {
		// Match @AppStorage's RawRepresentable format (JSON string, not Data)
		do {
			let data = try JSONEncoder().encode(accounts)
			if let jsonString = String(data: data, encoding: .utf8) {
				store.set(jsonString, forKey: key)
			}
		} catch {
			print("Failed to encode accounts: \(error)")
		}
	}
}

// MARK: - MockAccountStorage (for testing)

#if DEBUG
/// In-memory account storage for unit testing.
final class MockAccountStorage: AccountStorage, @unchecked Sendable {
	private var accounts: [VercelAccount] = []
	private let lock = NSLock()

	/// Track save operations for test assertions
	private(set) var saveCallCount = 0

	func loadAccounts() -> [VercelAccount] {
		lock.lock()
		defer { lock.unlock() }
		return accounts
	}

	func saveAccounts(_ accounts: [VercelAccount]) {
		lock.lock()
		defer { lock.unlock() }
		self.accounts = accounts
		saveCallCount += 1
	}

	/// Pre-populate accounts for testing
	func setAccounts(_ accounts: [VercelAccount]) {
		lock.lock()
		defer { lock.unlock() }
		self.accounts = accounts
	}

	/// Clear all data (useful for test setup/teardown)
	func clearAll() {
		lock.lock()
		defer { lock.unlock() }
		accounts.removeAll()
		saveCallCount = 0
	}
}
#endif
