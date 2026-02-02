//
//  IntentHandler.swift
//  SelectWidgetAccountIntent
//
//  Created by Daniel Eden on 31/05/2021.
//

import Intents

class IntentHandler: INExtension, SelectAccountIntentHandling {
	private let accountStorage: AccountStorage = UserDefaultsAccountStorage()

	func provideProjectOptionsCollection(for intent: SelectAccountIntent) async throws -> INObjectCollection<WidgetProject> {
		guard let account = intent.account,
					let account = accountStorage.loadAccounts().first(where: { $0.id == account.identifier }) else {
			return .init(items: [])
		}

		var request = VercelAPI.request(for: .projects(), with: account.id, queryItems: [URLQueryItem(name: "limit", value: "100")])

		try await MainActor.run {
			guard let session = VercelSession(account: account) else {
				return
			}
			try session.signRequest(&request)
		}

		let (data, _) = try await URLSession.shared.data(for: request)
		let decoded = try JSONDecoder().decode(VercelProject.APIResponse.self, from: data)
		return .init(items: [WidgetProject(identifier: nil, display: "All Projects")] + decoded.projects.map { WidgetProject(identifier: $0.id, display: $0.name) })
	}

	func provideAccountOptionsCollection(for _: SelectAccountIntent) async throws -> INObjectCollection<WidgetAccount> {
		let accounts = accountStorage.loadAccounts()
			.map { account in
				WidgetAccount(identifier: account.id, display: account.name ?? account.username)
			}

		return INObjectCollection(items: accounts)
	}

	override func handler(for _: INIntent) -> Any {
		return self
	}

	func defaultAccount(for _: SelectAccountIntent) -> WidgetAccount? {
		guard let firstAccount = accountStorage.loadAccounts().first else {
			return nil
		}

		return WidgetAccount(
			identifier: firstAccount.id,
			display: firstAccount.name ?? firstAccount.username
		)
	}
	
	func defaultProject(for intent: SelectAccountIntent) -> WidgetProject? {
		return WidgetProject(identifier: nil, display: "All Projects")
	}
}
