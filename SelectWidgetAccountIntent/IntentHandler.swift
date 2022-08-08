//
//  IntentHandler.swift
//  SelectWidgetAccountIntent
//
//  Created by Daniel Eden on 31/05/2021.
//

import Intents

class IntentHandler: INExtension, SelectAccountIntentHandling {
	static let defaultAccountDisplayString = "Default Account"

	func provideAccountOptionsCollection(for _: SelectAccountIntent) async throws -> INObjectCollection<WidgetAccount> {
		let accounts = Preferences.accounts
			.map { account in
				WidgetAccount(identifier: account.id, display: account.name ?? account.username)
			}

		return INObjectCollection(items: accounts)
	}

	override func handler(for _: INIntent) -> Any {
		return self
	}

	func defaultAccount(for _: SelectAccountIntent) -> WidgetAccount? {
		guard let firstAccount = Preferences.accounts.first else {
			return nil
		}

		return WidgetAccount(
			identifier: firstAccount.id,
			display: IntentHandler.defaultAccountDisplayString
		)
	}
}
