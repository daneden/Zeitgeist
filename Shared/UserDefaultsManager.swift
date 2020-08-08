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
  var keychain: Keychain
  static let shared = UserDefaultsManager()
  
  init() {
    self.keychain = Keychain(service: "me.daneden.Zeitgeist")
    
    self.token = self.keychain["vercelToken"]
  }
  
  @Published var token: String? {
    didSet {
      // Prevent warnings about existing keys on KeychainAccess
      self.keychain["vercelToken"] = nil
      self.keychain["vercelToken"] = self.token
      self.objectWillChange.send()
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
