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
    // Remove sensitive info stored in versions <1.1
    if UserDefaults.standard.string(forKey: "ZeitToken") != nil {
      UserDefaults.standard.set(nil, forKey: "ZeitToken")
    }
    
    self.keychain = Keychain(service: "me.daneden.Zeitgeist")
    self.token = self.keychain["vercelToken"]
  }
  
  @Published var token: String? {
    didSet {
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
