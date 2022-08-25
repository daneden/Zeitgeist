//
//  Session.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Combine
import Foundation
import SwiftUI

enum SessionError: Error {
	case notAuthenticated
}

extension SessionError: CustomStringConvertible {
	var description: String {
		switch self {
		case .notAuthenticated:
			return "The chosen account has not been authenticated on this device"
		}
	}
}

extension VercelAccount {
	func deepEqual(to comparison: VercelAccount) -> Bool {
		self.id == comparison.id &&
		self.name == comparison.name &&
		self.username == comparison.username &&
		self.avatar == comparison.avatar
	}
}

class VercelSession: ObservableObject {
	@AppStorage(Preferences.authenticatedAccounts)
	private var authenticatedAccounts

	@Published var account: VercelAccount {
		willSet {
			if newValue.id != account.id {
				accountLastUpdated = nil
			}
		}
	}
	
	private var accountLastUpdated: Date? = nil
	@Published private(set) var requestsDenied = false
	
	init(account: VercelAccount) {
		self.account = account
	}
	
	func refreshAccount() async {
		accountLastUpdated = .now
		let moreRecentAccount = await loadAccount()
		
		if let moreRecentAccount = moreRecentAccount,
			 account != moreRecentAccount {
			self.account.updateAccount(to: moreRecentAccount)
			if let index = authenticatedAccounts.firstIndex(of: account) {
				authenticatedAccounts[index] = moreRecentAccount
			}
		}
	}

	var authenticationToken: String? {
		return KeychainItem(account: account.id).wrappedValue
	}

	var isAuthenticated: Bool {
		authenticationToken != nil
	}

	@MainActor
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
		guard let authenticationToken = authenticationToken else {
			throw SessionError.notAuthenticated
		}
		
		if accountLastUpdated == nil {
			Task { await refreshAccount() }
		} else if let accountLastUpdated = accountLastUpdated,
							accountLastUpdated.distance(to: .now) > 60 * 60 {
			Task { await refreshAccount() }
		}

		request.addValue("Bearer \(authenticationToken)", forHTTPHeaderField: "Authorization")
	}
}

extension VercelSession {
	static func addAccount(id: String, token: String) async {
		guard id != .NullValue else { return }

		KeychainItem(account: id).wrappedValue = token

		let urlString = "https://api.vercel.com/v2/\(id.isTeam ? "teams/\(id)?teamId=\(id)" : "user")"
		var request = URLRequest(url: URL(string: urlString)!)

		do {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			let (data, _) = try await URLSession.shared.data(for: request)
			let decoded = try JSONDecoder().decode(VercelAccount.self, from: data)

			DispatchQueue.main.async {
				withAnimation {
					if let index = Preferences.accounts.firstIndex(where: { $0.id == decoded.id }) {
						Preferences.accounts[index] = decoded
					} else {
						Preferences.accounts.append(decoded)
					}
				}
			}
		} catch {
			print("Encountered an error when adding account with ID \(id)")
			print(error)
		}
	}

	static func deleteAccount(id: String) {
		let keychain = KeychainItem(account: id)

		withAnimation {
			Preferences.accounts.removeAll { id == $0.id }
			keychain.wrappedValue = nil
		}
	}
}
