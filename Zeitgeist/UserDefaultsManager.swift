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
  @Published var token: String? = UserDefaults.standard.string(forKey: "ZeitToken") {
    didSet {
      UserDefaults.standard.set(self.token, forKey: "ZeitToken")
      self.objectWillChange.send()
    }
  }

  @Published var fetchPeriod: Int? = UserDefaults.standard.integer(forKey: "FetchPeriod") {
    didSet {
      UserDefaults.standard.set(self.fetchPeriod, forKey: "FetchPeriod")
      self.objectWillChange.send()
    }
  }
}
