//
//  Preferences.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import Foundation
import SwiftUI

struct Preferences {
  enum Keys: String {
    case authenticatedAccountIds,
         notificationsEnabled,
         deploymentNotificationsProductionOnly,
         deploymentReadyNotificationIds,
         deploymentErrorNotificationIds,
         deploymentNotificationIds
    
  }
  
  typealias AppStorageKVPair<T> = (key: Keys, value: T)
  
  static let deploymentNotificationsProductionOnly: AppStorageKVPair<[VercelProject.ID]> = (.deploymentNotificationsProductionOnly, [])
  static let deploymentReadyNotificationIds: AppStorageKVPair<[VercelProject.ID]> = (.deploymentReadyNotificationIds, [])
  static let deploymentErrorNotificationIds: AppStorageKVPair<[VercelProject.ID]> = (.deploymentErrorNotificationIds, [])
  static let deploymentNotificationIds: AppStorageKVPair<[VercelProject.ID]> = (.deploymentNotificationIds, [])


  static let store = UserDefaults(suiteName: "group.me.daneden.Zeitgeist")!
  
  @AppStorage(Keys.authenticatedAccountIds.rawValue, store: Preferences.store)
  static var authenticatedAccountIds: AccountIDs = []
  
  @AppStorage(Keys.notificationsEnabled.rawValue) static var notificationsEnabled = false
}

extension AppStorage {
  init(_ kv: Preferences.AppStorageKVPair<Value>) where Value: RawRepresentable, Value.RawValue == String {
    self.init(wrappedValue: kv.value, kv.key.rawValue, store: Preferences.store)
  }
}
