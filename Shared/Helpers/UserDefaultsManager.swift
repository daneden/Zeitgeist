//
//  UserDefaultsManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine
import KeychainAccess

class UserDefaultsManager: ObservableObject {
  var keychain: KeyStore
  static let shared = UserDefaultsManager()
  
  init() {
    self.keychain = KeyStore()
    
    self.token = migrateKeychain() ?? self.keychain.retrieve()
  }
  
  @Published var token: String? {
    didSet {
      if let newValue = self.token {
        self.keychain.store(token: newValue)
      } else {
        self.keychain.clear()
      }

      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    }
  }
  
  @Published var currentTeam: String? = UserDefaults.standard.string(forKey: "SelectedTeam") {
    didSet {
      UserDefaults.standard.set(self.currentTeam, forKey: "SelectedTeam")
      self.objectWillChange.send()
    }
  }
  
  @Published var isSubscribed: Bool? = UserDefaults.standard.bool(forKey: "IsSubscribed") {
    didSet {
      UserDefaults.standard.set(self.isSubscribed, forKey: "IsSubscribed")
      self.objectWillChange.send()
    }
  }
}

func migrateKeychain() -> String? {
  let keychain = Keychain(service: "me.daneden.Zeitgeist", accessGroup: "group.me.daneden.Zeitgeist.shared")
  
  return keychain["vercelToken"]
}
