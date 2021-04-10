//
//  IntentHandler.swift
//  SelectTeamIntent
//
//  Created by Daniel Eden on 04/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Intents

class IntentHandler: INExtension, SelectTeamIntentHandling {
  func resolveTeam(for intent: SelectTeamIntent, with completion: @escaping (TeamResolutionResult) -> Void) {
    if let team = intent.team {
      completion(.success(with: team))
    }
  }
  
  func provideTeamOptionsCollection(for intent: SelectTeamIntent, with completion: @escaping (INObjectCollection<Team>?, Error?) -> Void) {
    let dispatchGroup = DispatchGroup()
    var teams = [Team]()
    _ = Session.shared.accounts.map { (account) in
      dispatchGroup.enter()
      
      let account = VercelAccount(id: account.key)
      let fetcher = VercelFetcher(account: account, withTimer: false)
      fetcher.loadAccount { (account, error) in
        if let account = account {
          teams.append(Team(identifier: account.id, display: account.name ?? ""))
        } else if error == nil {
          teams.append(Team(identifier: nil, display: "Personal"))
        }
        
        dispatchGroup.leave()
      }
    }
    
    dispatchGroup.notify(queue: .main) {
      let collection = INObjectCollection(items: teams)
      completion(collection, nil)
    }
  }
  
  override func handler(for intent: INIntent) -> Any {
      // This is the default implementation.  If you want different objects to handle different intents,
      // you can override this and return the handler you want for that particular intent.
      
      return self
  }
    
}
