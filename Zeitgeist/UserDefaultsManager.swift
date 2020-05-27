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
  
  @Published var currentTeam: String? = UserDefaults.standard.string(forKey: "SelectedTeam") {
    didSet {
      UserDefaults.standard.set(self.currentTeam, forKey: "SelectedTeam")
      self.objectWillChange.send()
    }
  }
}
