//
//  NotificationManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation
import SwiftUI

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
  
  @AppStorage("deploymentNotificationIds") static var deploymentNotificationIds: [VercelProject.ID] = []
  @AppStorage("deploymentErrorNotificationIds") static var deploymentErrorNotificationIds: [VercelProject.ID] = []
  @AppStorage("deploymentReadyNotificationIds") static var deploymentReadyNotificationIds: [VercelProject.ID] = []
  
  @AppStorage("allowDeploymentNotifications") static var allowDeploymentNotifications = true
  @AppStorage("allowDeploymentErrorNotifications") static var allowDeploymentErrorNotifications = true
  @AppStorage("allowDeploymentReadyNotifications") static var allowDeploymentReadyNotifications = true
  
  static func userAllowedNotifications(for eventType: ZPSEventType, with projectId: VercelProject.ID) -> Bool {
    switch eventType {
    case .deployment:
      return deploymentNotificationIds.contains { $0 == projectId }
    case .deploymentError:
      return deploymentErrorNotificationIds.contains { $0 == projectId }
    case .deploymentReady:
      return deploymentReadyNotificationIds.contains { $0 == projectId }
    default:
      // TODO: Add proper handling for event notifications and migrate to notifications based on project subscriptions
      return true
    }
  }
  
  func toggleNotifications(_ on: Bool, for projectId: VercelProject.ID) {
    if on {
      Self.deploymentNotificationIds.append(projectId)
      Self.deploymentErrorNotificationIds.append(projectId)
      Self.deploymentReadyNotificationIds.append(projectId)
    } else {
      Self.deploymentNotificationIds.removeAll { $0 == projectId }
      Self.deploymentErrorNotificationIds.removeAll { $0 == projectId }
      Self.deploymentReadyNotificationIds.removeAll { $0 == projectId }
    }
    
    Self.deploymentErrorNotificationIds.removeDuplicates()
    Self.deploymentReadyNotificationIds.removeDuplicates()
    Self.deploymentNotificationIds.removeDuplicates()
  }
}
