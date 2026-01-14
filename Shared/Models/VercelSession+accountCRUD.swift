//
//  VercelSession+accountCRUD.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 23/09/2022.
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

// MARK: - Account CRUD Operations

extension VercelSession {
	/// Adds a new account after validating the token with the Vercel API
	/// - Parameters:
	///   - id: The account ID (user ID or team ID)
	///   - token: The OAuth token for the account
	/// - Returns: A result containing the validated account or an error
	@MainActor
	static func addAccount(id: String, token: String) async -> Result<VercelAccount, AccountError> {
		guard id != .NullValue else {
			return .failure(.invalidId)
		}

		// Build URL safely without force unwrap
		let urlString = "https://api.vercel.com/v2/\(id.isTeam ? "teams/\(id)?teamId=\(id)" : "user")"
		guard let url = URL(string: urlString) else {
			return .failure(.invalidId)
		}

		// Validate token with API BEFORE storing in keychain
		var request = URLRequest(url: url)
		request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

		do {
			let (data, response) = try await URLSession.shared.data(for: request)

			// Verify the response is successful before storing token
			guard let httpResponse = response as? HTTPURLResponse,
						(200...299).contains(httpResponse.statusCode) else {
				return .failure(.invalidToken)
			}

			let decoded = try JSONDecoder().decode(VercelAccount.self, from: data)

			// Only store token after successful validation
			KeychainItem(account: id).wrappedValue = token

			// Update preferences (already on MainActor)
			withAnimation {
				if let index = Preferences.accounts.firstIndex(where: { $0.id == decoded.id }) {
					Preferences.accounts[index] = decoded
				} else {
					Preferences.accounts.append(decoded)
				}
			}

			NotificationCenter.default.post(name: .VercelAccountAddedNotification, object: nil)

			#if os(iOS)
			await UIApplication.shared.registerForRemoteNotifications()
			#elseif os(macOS)
			await NSApplication.shared.registerForRemoteNotifications()
			#endif

			return .success(decoded)

		} catch let error as DecodingError {
			return .failure(.decodingError(error))
		} catch {
			return .failure(.networkError(error))
		}
	}

	/// Deletes an account and removes its credentials from the keychain
	/// - Parameter id: The account ID to delete
	@MainActor
	static func deleteAccount(id: String) {
		let keychain = KeychainItem(account: id)
		keychain.wrappedValue = nil

		guard let accountIndex = Preferences.accounts.firstIndex(where: { $0.id == id }) else {
			return
		}

		NotificationCenter.default.post(name: .VercelAccountWillBeRemovedNotification, object: accountIndex)

		withAnimation {
			_ = Preferences.accounts.remove(at: accountIndex)
		}
	}
}
