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
  
  /**
   Requests notification permissions and enables notifications, or removes pending notifications when toggled off.
   - Parameters:
   - on: Whether notifications should be enabled (true) or disabled (false)
   - bindingTo: Optional binding to reflect the notification permission state. If authorization fails, the binding is updated to `false`.
   */
  func toggleNotifications(on enabled: Bool, bindingTo: Binding<Bool>? = nil) {
    if enabled {
      notificationCenter.requestAuthorization(options: [.alert, .sound]) { success, error in
        if success {
          print("Enabled notifications")
          
          DispatchQueue.main.async {            
            if let binding = bindingTo {
              binding.wrappedValue = true
            }
          }
        } else if let error = error {
          print(error.localizedDescription)
          
          DispatchQueue.main.async {
            if let binding = bindingTo {
              binding.wrappedValue = false
            }
          }
        }
      }
    } else {
      DispatchQueue.main.async {
        self.notificationCenter.removeAllPendingNotificationRequests()
      }
    }
  }
  
  @AppStorage("allowDeploymentNotifications") static var allowDeploymentNotifications = true
  @AppStorage("allowDeploymentErrorNotifications") static var allowDeploymentErrorNotifications = true
  @AppStorage("allowDeploymentReadyNotifications") static var allowDeploymentReadyNotifications = true
  
  static func userAllowedNotifications(for eventType: ZPSEventType) -> Bool {
    switch eventType {
    case .Deployment:
      return allowDeploymentNotifications
    case .DeploymentError:
      return allowDeploymentErrorNotifications
    case .DeploymentReady:
      return allowDeploymentReadyNotifications
    }
    
  }
}
