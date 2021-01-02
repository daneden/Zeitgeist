//
//  VercelStore.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

struct DefaultStore<T> {
  static func create() -> [String: [T]] {
    return ["-1": [T]()]
  }
}

import Foundation

protocol VercelStore: ObservableObject {
  associatedtype Element
  
  var store: [String: [Element]] { get }
  
  func updateStore(forTeam: String?, newValue: [Element])
}

class DeploymentsStore: VercelStore {
  // Deployments always start with an empty array for personal teams (identified in Zeitgeist by "-1")
  @Published var store: [String: [Deployment]] = DefaultStore<Deployment>.create()
  
  func updateStore(forTeam teamId: String?, newValue: [Deployment]) {
    let id = teamId ?? "-1"
    store[id] = newValue
  }
}

class ProjectsStore: VercelStore {
  @Published var store: [String: [Project]] = DefaultStore<Project>.create()
  
  func updateStore(forTeam teamId: String?, newValue: [Project]) {
    let id = teamId ?? "-1"
    store[id] = newValue
  }
}
