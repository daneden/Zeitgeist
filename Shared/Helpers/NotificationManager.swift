//
//  NotificationManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation
import SwiftUI
import UserNotifications

class NotificationManager {
  static let shared = NotificationManager()
  private let notificationCenter = UNUserNotificationCenter.current()
  
  @AppStorage(Preferences.Keys.notificationsEnabled.rawValue) var notificationsEnabled = false {
    didSet {
      Task {
        await self.toggleNotifications(notificationsEnabled)
      }
    }
  }
  
  /**
   Requests notification permissions and enables notifications, or removes pending notifications when toggled off.
   - Parameters:
   - on: Whether notifications should be enabled (true) or disabled (false)
   */
  @discardableResult
  func toggleNotifications(_ enabled: Bool) async -> Bool {
    if enabled {
      let result = try? await notificationCenter.requestAuthorization(options: [.alert, .sound])
      return result ?? false
    } else {
      notificationCenter.removeAllPendingNotificationRequests()
      return false
    }
  }
  
  private static func requestAuthorization() {
    if !(deploymentNotificationIds + deploymentErrorNotificationIds + deploymentReadyNotificationIds).isEmpty {
      Task {
        try? await UNUserNotificationCenter.current().requestAuthorization()
      }
    }
  }
  
  @AppStorage("deploymentNotificationIds") static var deploymentNotificationIds: [VercelProject.ID] = [] {
    didSet { requestAuthorization() }
  }
  
  @AppStorage("deploymentErrorNotificationIds") static var deploymentErrorNotificationIds: [VercelProject.ID] = [] {
    didSet { requestAuthorization() }
  }
  
  @AppStorage("deploymentReadyNotificationIds") static var deploymentReadyNotificationIds: [VercelProject.ID] = [] {
    didSet { requestAuthorization() }
  }
  
  static func userAllowedNotifications(for eventType: ZPSEventType, with projectId: VercelProject.ID) -> Bool {
    switch eventType {
    case .deployment:
      return deploymentNotificationIds.contains(projectId)
    case .deploymentError:
      return deploymentErrorNotificationIds.contains(projectId)
    case .deploymentReady:
      return deploymentReadyNotificationIds.contains(projectId)
    default:
      // TODO: Add proper handling for event notifications and migrate to notifications based on project subscriptions
      return true
    }
  }
}
