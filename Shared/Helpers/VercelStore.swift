//
//  VercelStore.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

protocol VercelStore: ObservableObject {
  associatedtype Element
  
  var store: [String: [Element]] { get }
  
  func updateStore(forTeam: String?, newValue: [Element])
}

class DeploymentsStore: VercelStore {
  // Deployments always start with an empty array for personal teams (identified in Zeitgeist by "-1")
  @Published var store: [String: [Deployment]] = ["-1": []]
  
  func updateStore(forTeam teamId: String?, newValue: [Deployment]) {
    let id = teamId ?? "-1"
    store[id] = newValue
  }
}

class ProjectsStore: VercelStore {
  @Published var store: [String: [Project]] = ["-1": []]
  
  func updateStore(forTeam teamId: String?, newValue: [Project]) {
    let id = teamId ?? "-1"
    store[id] = newValue
  }
}
