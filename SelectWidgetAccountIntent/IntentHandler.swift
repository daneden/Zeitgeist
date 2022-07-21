//
//  IntentHandler.swift
//  SelectWidgetAccountIntent
//
//  Created by Daniel Eden on 31/05/2021.
//

import Intents

class IntentHandler: INExtension, SelectAccountIntentHandling {
  static let defaultAccountDisplayString = "Default Account"
  
  func provideAccountOptionsCollection(for intent: SelectAccountIntent) async throws -> INObjectCollection<WidgetAccount> {
    let accountIds = Preferences.accountIds
    async let accounts = accountIds.asyncMap { id -> VercelAccount? in
      let accountLoader = VercelSession()
      accountLoader.accountId = id
      
      return await accountLoader.loadAccount()
    }.compactMap({ $0 })
      .map { account in
        WidgetAccount(identifier: account.id, display: account.name)
      }
    
    return await INObjectCollection(items: accounts)
  }
  
  override func handler(for intent: INIntent) -> Any {
    return self
  }
  
  func defaultAccount(for intent: SelectAccountIntent) -> WidgetAccount? {
    guard let firstAccountId = Preferences.accountIds.first else {
      return nil
    }
    
    return WidgetAccount(
      identifier: firstAccountId,
      display: IntentHandler.defaultAccountDisplayString
    )
  }
}
