//
//  VercelStore.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

protocol VercelStore {
  associatedtype Element
  
  var store: [String: [Element]] { get set }
  
  mutating func updateStore(forTeam: String?, newValue: [Element])
}

struct DeploymentsStore: VercelStore {
  // Deployments always start with an empty array for personal teams (identified in Zeitgeist by "-1")
  var store: [String: [Deployment]] = ["-1": []]
  
  mutating func updateStore(forTeam teamId: String?, newValue: [Deployment]) {
    let id = teamId ?? "-1"
    store[id] = newValue
  }
}

struct ProjectsStore: VercelStore {
  var store: [String: [Project]] = ["-1": []]
  
  mutating func updateStore(forTeam teamId: String?, newValue: [Project]) {
    let id = teamId ?? "-1"
    store[id] = newValue
  }
}
