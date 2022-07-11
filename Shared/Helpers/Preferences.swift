//
//  Preferences.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import Foundation
import SwiftUI

class Preferences {
  static let store = UserDefaults(suiteName: "group.me.daneden.Zeitgeist")!
  
  @AppStorage("authenticatedAccountIds", store: Preferences.store)
  static var authenticatedAccountIds: AccountIDs = []
}
