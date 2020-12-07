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
    let fetcher = VercelFetcher.shared
    fetcher.loadTeams { (teams, error) in
      if let result = teams {
        var fetchedTeams = result.map { (team) -> Team in
          Team(identifier: team.id, display: team.name)
        }
        
        fetchedTeams.append(Team(identifier: nil, display: "Personal"))
        
        let collection = INObjectCollection(items: fetchedTeams)
        completion(collection, nil)
      } else {
        print(error?.localizedDescription ?? "Error fetching teams")
      }
    }
  }
  
  override func handler(for intent: INIntent) -> Any {
      // This is the default implementation.  If you want different objects to handle different intents,
      // you can override this and return the handler you want for that particular intent.
      
      return self
  }
    
}
