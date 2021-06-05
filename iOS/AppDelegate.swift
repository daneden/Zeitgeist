//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import UIKit
import SwiftUI
import Purchases

#if DEBUG
let platform = "ios_sandbox"
#else
let platform = "ios"
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
  @AppStorage("notificationsEnabled") var notificationsEnabled = false
  @AppStorage("activeSupporterSubscription") var activeSubscription = false
  
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
    if notificationsEnabled {
      UIApplication.shared.registerForRemoteNotifications()
    }
    
    UNUserNotificationCenter.current().delegate = self
    
    setupRevenueCat()
    
    return true
  }
  
  func applicationWillEnterForeground(_ application: UIApplication) {
    UNUserNotificationCenter.current().removeAllDeliveredNotifications()
  }
  
  // MARK: In-App Purchase Setup
  func setupRevenueCat() {
    Purchases.configure(withAPIKey: "BtsJTlCfcJkRXMbWTTraNErvIsCcLkLb")
  }
  
  // MARK: Notifications
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("Registered for remote notifications; registering in Zeitgeist Postal Service (ZPS)")
    
    _ = Session.shared.authenticatedAccountIds.map { id in
      let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
      let url = URL(string: "https://zeitgeist.link/api/registerPushNotifications?user_id=\(id)&device_id=\(token)&platform=\(platform)")!
      let request = URLRequest(url: url)
      
      URLSession.shared.dataTask(with: request) { (data, _, error) in
        if let error = error {
          print(error)
          self.notificationsEnabled = false
        }
        
        if data != nil {
          print("Successfully registered device ID to ZPS")
          self.notificationsEnabled = true
        }
      }.resume()
    }
    
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print(error.localizedDescription)
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    print("Received remote notification")
    
    if !activeSubscription {
      print("User is not know to be an active subscriber; supressing notification")
      completionHandler(.noData)
      return
    }
    
    do {
      let title: String? = userInfo["title"] as? String
      guard let body: String = userInfo["body"] as? String else {
        throw ZPSError.FieldCastingError(field: userInfo["body"])
      }
      
      let deploymentId: String? = userInfo["deploymentId"] as? String
      let teamId: String? = userInfo["teamId"] as? String
      guard let eventType: ZPSEventType = ZPSEventType(rawValue: userInfo["eventType"] as? String ?? "") else {
        throw ZPSError.EventTypeCastingError(eventType: userInfo["eventType"])
      }
      
      if NotificationManager.notificationsAllowedForEventType(eventType) {
        let content = UNMutableNotificationContent()
        
        if let title = title {
          content.title = title
          content.body = body
        } else {
          content.title = body
        }
        
        content.sound = .default
        content.threadIdentifier = deploymentId ?? UUID().uuidString
        content.categoryIdentifier = ZPSNotificationCategory.Deployment.rawValue
        content.userInfo = [
          "DEPLOYMENT_ID": "\(deploymentId ?? "nil")",
          "TEAM_ID": "\(teamId ?? "-1")"
        ]
        
        let notificationID = "\(content.threadIdentifier)-\(eventType.rawValue)"
        
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
        completionHandler(.newData)
      } else {
        completionHandler(.noData)
      }
    } catch {
      switch error {
      case ZPSError.FieldCastingError(let field):
        print(field.debugDescription)
      case ZPSError.EventTypeCastingError(let eventType):
        print(eventType.debugDescription)
      default:
        print("")
      }
      
      print(error.localizedDescription)
      completionHandler(.failed)
    }
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
    case ZPSNotificationCategory.Deployment.rawValue:
      UIApplication.shared.open(URL(string: "zeitgeist://deployment/\(teamID)/\(deploymentID)")!, options: [:])
    default:
      print("Uncaught notification category identifies")
    }
    
    completionHandler()
  }
}
