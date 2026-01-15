//
//  AccountManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/01/2026.
//

import Foundation
import SwiftUI

// MARK: - Account Operation Errors

enum AccountError: Error {
	case invalidId
	case invalidToken
	case networkError(Error)
	case decodingError(Error)
}

extension AccountError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .invalidId:
			return "Invalid account ID provided"
		case .invalidToken:
			return "The provided token is invalid or has been revoked"
		case .networkError(let error):
			return "Network error: \(error.localizedDescription)"
		case .decodingError(let error):
			return "Failed to decode account data: \(error.localizedDescription)"
		}
	}
}

// MARK: - AccountManager

/// Centralized manager for multi-account authentication state.
///
/// `AccountManager` consolidates account lifecycle management, session creation,
/// and account switching into a single `@Observable` class. This provides:
/// - Single source of truth for account state
/// - Reactive updates via `@Observable` (no NotificationCenter needed)
/// - Clear ownership of session lifecycle
/// - Testability via protocol injection
///
/// ## Usage
/// ```swift
/// // In App struct
/// @State private var accountManager = AccountManager()
///
/// var body: some Scene {
///     WindowGroup {
///         ContentView()
///             .environment(accountManager)
///     }
/// }
///
/// // In views
/// @Environment(AccountManager.self) var accountManager
/// ```
@Observable
@MainActor
final class AccountManager {
	// MARK: - Published State

	/// All authenticated accounts
	private(set) var accounts: [VercelAccount] = []

	/// Currently active session (nil if no account selected or token invalid)
	private(set) var currentSession: VercelSession?

	/// ID of the currently selected account.
	/// Setting this automatically updates `currentSession`.
	var selectedAccountId: VercelAccount.ID? {
		didSet {
			if oldValue != selectedAccountId {
				updateCurrentSession()
				persistSelectedAccountId()
			}
		}
	}

	// MARK: - Computed Properties

	/// Currently selected account (derived from `selectedAccountId`)
	var selectedAccount: VercelAccount? {
		guard let id = selectedAccountId else { return nil }
		return accounts.first { $0.id == id }
	}

	/// Whether any accounts are authenticated
	var hasAccounts: Bool { !accounts.isEmpty }

	/// Whether the current session is valid and authenticated
	var isAuthenticated: Bool { currentSession?.isAuthenticated == true }

	// MARK: - Dependencies

	private let storage: AccountStorage
	private let tokenStore: TokenStore

	// MARK: - Initialization

	/// Creates an AccountManager with the specified storage backends.
	/// - Parameters:
	///   - storage: Backend for persisting account metadata. Defaults to UserDefaults.
	///   - tokenStore: Backend for secure token storage. Defaults to Keychain.
	init(storage: AccountStorage = UserDefaultsAccountStorage(),
	     tokenStore: TokenStore = KeychainTokenStore()) {
		self.storage = storage
		self.tokenStore = tokenStore
		loadAccounts()
	}

	// MARK: - Account Operations

	/// Adds a new account after validating the token with the Vercel API.
	///
	/// This method:
	/// 1. Validates the token by fetching account info from Vercel API
	/// 2. Stores the token securely in the keychain
	/// 3. Adds the account to the account list
	/// 4. Automatically selects the new account
	/// 5. Registers for push notifications
	///
	/// - Parameters:
	///   - id: The account ID (user ID or team ID from OAuth response)
	///   - token: The OAuth token for the account
	/// - Returns: A result containing the validated account or an error
	func addAccount(id: String, token: String) async -> Result<VercelAccount, AccountError> {
		guard id != .NullValue else {
			return .failure(.invalidId)
		}

		// Validate token with API first
		guard let account = await validateAndFetchAccount(id: id, token: token) else {
			return .failure(.invalidToken)
		}

		// Store token securely (only after validation succeeds)
		tokenStore.setToken(token, for: id)

		// Update account list
		withAnimation {
			if let index = accounts.firstIndex(where: { $0.id == account.id }) {
				accounts[index] = account
			} else {
				accounts.append(account)
			}
		}

		// Persist to storage
		storage.saveAccounts(accounts)

		// Auto-select the new account
		selectedAccountId = account.id

		// Register for push notifications
		await registerForNotifications()

		return .success(account)
	}

	/// Removes an account and its stored credentials.
	///
	/// If the deleted account was selected, automatically selects another account.
	///
	/// - Parameter id: The account ID to delete
	func deleteAccount(id: VercelAccount.ID) {
		// Remove token first
		tokenStore.removeToken(for: id)

		guard let index = accounts.firstIndex(where: { $0.id == id }) else {
			return
		}

		// Remove from list
		withAnimation {
			_ = accounts.remove(at: index)
		}

		// Persist changes
		storage.saveAccounts(accounts)

		// If deleted account was selected, select another
		if selectedAccountId == id {
			selectedAccountId = accounts.first?.id
		}
	}

	/// Switches to a different account.
	/// - Parameter account: The account to switch to (must exist in accounts list)
	func selectAccount(_ account: VercelAccount) {
		guard accounts.contains(where: { $0.id == account.id }) else { return }
		selectedAccountId = account.id
	}

	/// Refreshes the current account's metadata from the API.
	func refreshCurrentAccount() async {
		await currentSession?.refreshAccount()

		// Sync any account changes back to storage
		if let session = currentSession,
		   let index = accounts.firstIndex(where: { $0.id == session.account.id }) {
			accounts[index] = session.account
			storage.saveAccounts(accounts)
		}
	}

	// MARK: - Private Helpers

	private func loadAccounts() {
		accounts = storage.loadAccounts()

		// Restore previously selected account or default to first
		if let savedId = loadSelectedAccountId(), accounts.contains(where: { $0.id == savedId }) {
			selectedAccountId = savedId
		} else {
			selectedAccountId = accounts.first?.id
		}
	}

	private func updateCurrentSession() {
		guard let account = selectedAccount else {
			currentSession = nil
			return
		}

		// Create session (validates token exists via failable init)
		// Pass our tokenStore for consistency
		currentSession = VercelSession(account: account, tokenStore: tokenStore)
	}

	private func validateAndFetchAccount(id: String, token: String) async -> VercelAccount? {
		// Build URL for user or team endpoint
		let urlString = "https://api.vercel.com/v2/\(id.isTeam ? "teams/\(id)?teamId=\(id)" : "user")"
		guard let url = URL(string: urlString) else {
			return nil
		}

		var request = URLRequest(url: url)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		do {
			let (data, response) = try await URLSession.shared.data(for: request)

			guard let httpResponse = response as? HTTPURLResponse,
			      (200...299).contains(httpResponse.statusCode) else {
				return nil
			}

			return try JSONDecoder().decode(VercelAccount.self, from: data)
		} catch {
			print("Failed to validate account: \(error)")
			return nil
		}
	}

	private func registerForNotifications() async {
		#if os(iOS)
		UIApplication.shared.registerForRemoteNotifications()
		#elseif os(macOS)
		NSApplication.shared.registerForRemoteNotifications()
		#endif
	}

	// MARK: - Selected Account Persistence

	private let selectedAccountIdKey = "AccountManager.selectedAccountId"

	private func persistSelectedAccountId() {
		if let id = selectedAccountId {
			Preferences.store.set(id, forKey: selectedAccountIdKey)
		} else {
			Preferences.store.removeObject(forKey: selectedAccountIdKey)
		}
	}

	private func loadSelectedAccountId() -> VercelAccount.ID? {
		Preferences.store.string(forKey: selectedAccountIdKey)
	}
}

// MARK: - Environment Key

extension EnvironmentValues {
	/// The app's account manager for authentication state.
	@Entry var accountManager: AccountManager?
}
