//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

#if !os(macOS)
import UIKit
#endif
import SwiftUI
import WidgetKit

#if DEBUG
let platform = "ios_sandbox"
#else
let platform = "ios"
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
  @AppStorage(Preferences.Keys.notificationsEnabled.rawValue)
  private var notificationsEnabled = false
  
  @AppStorage(Preferences.Keys.authenticatedAccountIds.rawValue)
  private var authenticatedAccountIds: AccountIDs = [] {
    didSet {
      UIApplication.shared.registerForRemoteNotifications()
    }
  }
  
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    UIApplication.shared.registerForRemoteNotifications()
    
    UNUserNotificationCenter.current().getNotificationSettings { [self] settings in
      switch settings.authorizationStatus {
      case .denied, .notDetermined:
        self.notificationsEnabled = false
        return
      default:
        return
      }
    }
    
    UNUserNotificationCenter.current().delegate = self

    Task {
      await NotificationManager.shared.toggleNotifications(notificationsEnabled)
    }
    
    return true
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
  }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler:
                                @escaping () -> Void) {
    
    let userInfo = response.notification.request.content.userInfo
    
    guard let deploymentID = userInfo["DEPLOYMENT_ID"] as? String else {
      completionHandler()
      return
    }
    
    guard let teamID = userInfo["TEAM_ID"] as? String else {
      completionHandler()
      return
    }
    
    switch response.notification.request.content.categoryIdentifier {
    case ZPSNotificationCategory.deployment.rawValue:
      UIApplication.shared.open(URL(string: "zeitgeist://deployment/\(teamID)/\(deploymentID)")!, options: [:])
    default:
      print("Uncaught notification category identifier")
    }
    
    completionHandler()
  }
  
  func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    print("Registered for remote notifications; registering in Zeitgeist Postal Service (ZPS)")
    
    _ = Preferences.authenticatedAccountIds.map { id in
      let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
      let url = URL(string: "https://zeitgeist.link/api/registerPushNotifications?user_id=\(id)&device_id=\(token)&platform=\(platform)")!
      let request = URLRequest(url: url)
      
      URLSession.shared.dataTask(with: request) { (data, _, error) in
        if let error = error {
          print(error)
        }
        
        if data != nil {
          print("Successfully registered device ID to ZPS")
        }
      }.resume()
    }
    
  }
  
  func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print(error.localizedDescription)
  }
  
  func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("Received remote notification")
    WidgetCenter.shared.reloadAllTimelines()
    
    NotificationCenter.default.post(name: .ZPSNotification, object: nil)
    
    do {
      let title = userInfo["title"] as? String
      guard let body = userInfo["body"] as? String else {
        throw ZPSError.FieldCastingError(field: userInfo["body"])
      }
      
      guard let projectId = userInfo["projectId"] as? String else {
        throw ZPSError.FieldCastingError(field: userInfo["projectId"])
      }
      
      let deploymentId: String? = userInfo["deploymentId"] as? String
      let teamId: String? = userInfo["teamId"] as? String
      
      guard let eventType: ZPSEventType = ZPSEventType(rawValue: userInfo["eventType"] as? String ?? "") else {
        throw ZPSError.EventTypeCastingError(eventType: userInfo["eventType"])
      }
      
      if NotificationManager.userAllowedNotifications(for: eventType, with: projectId) {
        let content = UNMutableNotificationContent()
        
        if let title = title {
          content.title = title
          content.body = body
        } else {
          content.title = body
        }
        
        content.sound = .default
        content.threadIdentifier = projectId
        content.categoryIdentifier = ZPSNotificationCategory.deployment.rawValue
        content.userInfo = [
          "DEPLOYMENT_ID": "\(deploymentId ?? "nil")",
          "TEAM_ID": "\(teamId ?? "-1")",
          "PROJECT_ID": "\(projectId)"
        ]
        
        let notificationID = "\(content.threadIdentifier)-\(eventType.rawValue)"
        
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: nil)
        print("Pushing notification with ID \(notificationID)")
        UNUserNotificationCenter.current().add(request)
        completionHandler(.newData)
      } else {
        print("Notification suppressed due to user preferences")
        completionHandler(.noData)
      }
      
      return
    } catch {
      switch error {
      case ZPSError.FieldCastingError(let field):
        print(field.debugDescription)
      case ZPSError.EventTypeCastingError(let eventType):
        print(eventType.debugDescription)
      default:
        print("Unknown error occured when handling background notification")
      }
      
      print(error.localizedDescription)
      completionHandler(.failed)
      
      return
    }
  }
}
