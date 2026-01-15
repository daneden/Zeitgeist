//
//  Session.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import SwiftUI

// MARK: - Session Errors

enum SessionError: Error {
	case notAuthenticated
	case tokenNotFound(accountId: String)
}

extension SessionError: LocalizedError {
	var errorDescription: String? {
		switch self {
		case .notAuthenticated:
			return "The chosen account has not been authenticated on this device"
		case .tokenNotFound(let accountId):
			return "No authentication token found for account: \(accountId)"
		}
	}
}

// MARK: - VercelAccount Extension

extension VercelAccount {
	func deepEqual(to comparison: VercelAccount) -> Bool {
		self.id == comparison.id &&
		self.name == comparison.name &&
		self.username == comparison.username &&
		self.avatar == comparison.avatar
	}
}

// MARK: - VercelSession

@Observable
@MainActor
final class VercelSession {
	// MARK: - Properties

	private(set) var account: VercelAccount
	private(set) var requestsDenied = false
	private var accountLastUpdated: Date?
	private let tokenStore: TokenStore

	// MARK: - Initialization

	/// Failable initializer that validates the account has an authentication token
	/// - Parameters:
	///   - account: The account to create a session for
	///   - tokenStore: Backend for secure token storage. Defaults to Keychain.
	init?(account: VercelAccount, tokenStore: TokenStore = KeychainTokenStore()) {
		guard tokenStore.hasToken(for: account.id) else {
			return nil
		}
		self.account = account
		self.tokenStore = tokenStore
	}

	/// Initializer for contexts where token validation may be deferred (e.g., widgets)
	/// - Parameters:
	///   - account: The account to create a session for
	///   - tokenStore: Backend for secure token storage. Defaults to Keychain.
	///   - skipTokenValidation: Must be `true` to use this initializer
	init(account: VercelAccount, tokenStore: TokenStore = KeychainTokenStore(), skipTokenValidation: Bool) {
		precondition(skipTokenValidation, "Use init?(account:) for validated initialization")
		self.account = account
		self.tokenStore = tokenStore
	}

	// MARK: - Account Management

	func refreshAccount() async {
		accountLastUpdated = .now

		guard let moreRecentAccount = await loadAccount() else { return }
		guard !account.deepEqual(to: moreRecentAccount) else { return }

		account.updateAccount(to: moreRecentAccount)
		// Note: AccountManager.refreshCurrentAccount() handles persisting the updated account
	}

	// MARK: - Authentication
	var authenticationToken: String? {
		tokenStore.getToken(for: account.id)
	}

	var isAuthenticated: Bool {
		authenticationToken != nil
	}

	// MARK: - API Methods

	func loadAccount() async -> VercelAccount? {
		do {
			guard authenticationToken != nil else {
				return nil
			}

			var request = VercelAPI.request(for: .account(id: account.id), with: account.id)
			try signRequest(&request)

			let (data, response) = try await URLSession.shared.data(for: request)

			validateResponse(response)

			return try JSONDecoder().decode(VercelAccount.self, from: data)
		} catch {
			print(error)
			return nil
		}
	}

	func validateResponse(_ response: URLResponse) {
		if let response = response as? HTTPURLResponse,
			 response.statusCode == 403 {
			requestsDenied = true
		}
	}

	func signRequest(_ request: inout URLRequest) throws {
		guard let authenticationToken else {
			throw SessionError.tokenNotFound(accountId: account.id)
		}

		if accountLastUpdated == nil {
			Task { await refreshAccount() }
		} else if let accountLastUpdated,
							accountLastUpdated.distance(to: .now) > 60 * 60 {
			Task { await refreshAccount() }
		}

		request.addValue("Bearer \(authenticationToken)", forHTTPHeaderField: "Authorization")
	}
}

// MARK: - Environment Key

extension EnvironmentValues {
	@Entry var session: VercelSession?
}
