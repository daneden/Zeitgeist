//
//  UserDefaultsManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine

class UserDefaultsManager: ObservableObject {
  var keychain: KeyStore
  static let shared = UserDefaultsManager()
  
  init() {
    self.keychain = KeyStore()
    
    self.token = self.keychain.retrieve()
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
}
