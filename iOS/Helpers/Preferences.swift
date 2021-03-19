//
//  Preferences.swift
//  iOS
//
//  Created by Daniel Eden on 19/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

class Preferences {
  static var shared = Preferences()
  static var suiteName = "group.me.daneden.Eventually"
  
  var store = UserDefaults(suiteName: suiteName)!
  
  struct Keys {
    static let keywords = "keywords"
    static let colorTheme = "theme"
    static let purchasedProductIDs = "purchasedProductIDs"
    static let sessions = "sessions"
    static let ignoredCalendarIDs = "ignoredCalendarIDs"
    static let ignoredEventIDs = "ignoredEventIDs"
  }
}
