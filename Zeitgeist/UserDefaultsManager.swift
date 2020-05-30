//
//  UserDefaultsManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine
import Cocoa
import KeychainAccess

class UserDefaultsManager: ObservableObject {
  var keychain: Keychain
  
  init() {
    self.keychain = Keychain(service: "me.daneden.Zeitgeist")
    
    // Migrate sensitive info stored in versions <1.1
    if UserDefaults.standard.string(forKey: "ZeitToken") != nil && self.keychain["vercelToken"] == nil {
      self.keychain["vercelToken"] = UserDefaults.standard.string(forKey: "ZeitToken")
      UserDefaults.standard.set(nil, forKey: "ZeitToken")
    }
    
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

  @Published var fetchPeriod: Int? = UserDefaults.standard.integer(forKey: "FetchPeriod") {
    didSet {
      UserDefaults.standard.set(self.fetchPeriod, forKey: "FetchPeriod")
      self.objectWillChange.send()
    }
  }
  
  @Published var currentTeam: String? = UserDefaults.standard.string(forKey: "SelectedTeam") {
    didSet {
      UserDefaults.standard.set(self.currentTeam, forKey: "SelectedTeam")
      self.objectWillChange.send()
    }
  }
}
