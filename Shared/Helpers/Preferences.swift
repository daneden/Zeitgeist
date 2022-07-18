//
//  Preferences.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import Foundation
import SwiftUI

struct Preferences {
  enum Keys: String, RawRepresentable {
    case authenticatedAccountIds, notificationsEnabled
  }
  
  static let kAuthenticatedAccountIds = "authenticatedAccountIds"
  static let store = UserDefaults(suiteName: "group.me.daneden.Zeitgeist")!
  
  @AppStorage(Keys.authenticatedAccountIds.rawValue, store: Preferences.store)
  static var authenticatedAccountIds: AccountIDs = []
  
  @AppStorage(Keys.notificationsEnabled.rawValue) static var notificationsEnabled = false
}
