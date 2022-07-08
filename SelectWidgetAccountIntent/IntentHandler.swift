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
    let accountIds = Session.shared.authenticatedAccountIds
    async let accounts = accountIds.asyncMap { id -> Account? in
      let accountLoader = AccountViewModel(accountId: id)
      
      return await accountLoader.loadOnce()
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
    guard let firstAccountId = Session.shared.authenticatedAccountIds.first else {
      return nil
    }
    
    return WidgetAccount(
      identifier: firstAccountId,
      display: IntentHandler.defaultAccountDisplayString
    )
  }
}
