//
//  IntentHandler.swift
//  SelectWidgetAccountIntent
//
//  Created by Daniel Eden on 31/05/2021.
//

import Intents

class IntentHandler: INExtension, SelectAccountIntentHandling {
  static let defaultAccountDisplayString = "Default Account"
  
  func provideAccountOptionsCollection(for intent: SelectAccountIntent, with completion: @escaping (INObjectCollection<WidgetAccount>?, Error?) -> Void) {
    let dispatchGroup = DispatchGroup()
    var accounts = [WidgetAccount]()
    
    let loader = AccountLoader()
    
    let accountIds = Session.shared.authenticatedAccountIds
    _ = accountIds.map { accountId in
      dispatchGroup.enter()
      loader.loadAccount(withID: accountId) { result in
        switch result {
        case .success(let account):
          accounts.append(WidgetAccount(identifier: account.id, display: account.name))
        case .failure(let error):
          print(error.localizedDescription)
        }
        
        dispatchGroup.leave()
      }
    }
    
    dispatchGroup.notify(queue: .main) {
      let collection = INObjectCollection(items: accounts)
      completion(collection, nil)
    }
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
