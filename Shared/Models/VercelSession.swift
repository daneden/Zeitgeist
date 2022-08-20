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

	@Published var account: VercelAccount? {
		willSet {
			if account != nil {
				accountLastUpdated = nil
			}
		}
	}
	
	private var accountLastUpdated: Date? = nil
	
	init(account: VercelAccount? = nil) {
		self.account = account
	}
	
	func refreshAccount() async {
		accountLastUpdated = .now
		let moreRecentAccount = await loadAccount()
		
		if let moreRecentAccount = moreRecentAccount,
			 let account = account,
			 account != moreRecentAccount {
			self.account?.updateAccount(to: moreRecentAccount)
			if let index = authenticatedAccounts.firstIndex(of: account) {
				authenticatedAccounts[index] = moreRecentAccount
			}
		}
	}

	var authenticationToken: String? {
		guard let account = account else { return nil }
		return KeychainItem(account: account.id).wrappedValue
	}

	var isAuthenticated: Bool {
		account != nil && authenticationToken != nil
	}

	@MainActor
	func loadAccount() async -> VercelAccount? {
		do {
			guard let account = account, authenticationToken != nil else {
				return nil
			}

			var request = VercelAPI.request(for: .account(id: account.id), with: account.id)
			try signRequest(&request)

			let (data, _) = try await URLSession.shared.data(for: request)

			return try JSONDecoder().decode(VercelAccount.self, from: data)
		} catch {
			print(error)
			return nil
		}
	}

	func signRequest(_ request: inout URLRequest) throws {
		guard let authenticationToken = authenticationToken else {
			self.account = nil
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

		var request: URLRequest

		if id.isTeam {
			request = URLRequest(url: URL(string: "https://api.vercel.com/v2/teams/\(id)?teamId=\(id)")!)
		} else {
			request = URLRequest(url: URL(string: "https://api.vercel.com/v2/user")!)
		}

		do {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			let (data, _) = try await URLSession.shared.data(for: request)
			let decoded = try JSONDecoder().decode(VercelAccount.self, from: data)

			DispatchQueue.main.async {
				Preferences.accounts.append(decoded)
				Preferences.accounts = Preferences.accounts.removingDuplicates()
			}
		} catch {
			print("Encountered an error when adding account with ID \(id)")
			print(error)
		}
	}

	static func deleteAccount(id: String) {
		let keychain = KeychainItem(account: id)
		keychain.wrappedValue = nil

		withAnimation { Preferences.accounts.removeAll { id == $0.id } }
	}
}
