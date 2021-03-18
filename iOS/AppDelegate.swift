//
//  AppDelegate.swift
//  iOS
//
//  Created by Daniel Eden on 16/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import UIKit
import SwiftUI

#if DEBUG
let platform = "ios_sandbox"
#else
let platform = "ios"
#endif

class AppDelegate: NSObject, UIApplicationDelegate {
  @AppStorage("notificationsEnabled") var notificationsEnabled = false
  
  func applicationDidFinishLaunching(_ application: UIApplication) {
    if notificationsEnabled {
      UIApplication.shared.registerForRemoteNotifications()
    }
  }
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("Registered for remote notifications; registering in Zeitgeist Postal Service (ZPS)")
    guard let userId = VercelFetcher.shared.user?.id else { return }
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    let url = URL(string: "https://zeitgeist.link/api/registerPushNotifications?user_id=\(userId)&device_id=\(token)&platform=\(platform)")!
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
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print(error.localizedDescription)
  }
  
  func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
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
      
      let deployment = VercelFetcher.shared.deploymentsStore.store[teamId ?? "-1"]?.filter { $0.id == deploymentId }.first
      
      if NotificationManager.notificationsAllowedForEventType(eventType) {
        let content = UNMutableNotificationContent()
        
        if let title = title {
          content.title = title
        } else if deployment != nil {
          content.title = body
          content.body = "Tap to view deployment information"
        } else {
          content.body = body
        }
        
        content.sound = .default
        content.threadIdentifier = deploymentId ?? UUID().uuidString
        content.userInfo = [
          "DEPLOYMENT_ID": "\(deploymentId ?? "nil")",
          "TEAM_ID": "\(teamId ?? "-1")"
        ]
        content.categoryIdentifier = "DEPLOYMENT"
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
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
  
  func registerNotificationCategories() {
    let viewDeploymentAction = UNNotificationAction(identifier: "VIEW_DEPLOYMENT_ACTION", title: "View Deployment", options: .foreground)
    
    let deploymentCategory = UNNotificationCategory(identifier: "DEPLOYMENT", actions: [viewDeploymentAction], intentIdentifiers: [], options: [])
    UNUserNotificationCenter.current().setNotificationCategories([deploymentCategory])
  }
  
  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler:
                                @escaping () -> Void) {
    
    // Get the meeting ID from the original notification.
    let userInfo = response.notification.request.content.userInfo
    guard let deploymentID = userInfo["DEPLOYMENT_ID"] as? String else {
      completionHandler()
      return
    }
    
    guard let teamID = userInfo["TEAM_ID"] as? String else {
      completionHandler()
      return
    }
    
    // Perform the task associated with the action.
    switch response.actionIdentifier {
    case "VIEW_DEPLOYMENT_ACTION":
      UIApplication.shared.open(URL(string: "zeitgeist://deployment/\(teamID)/\(deploymentID)")!, options: [.universalLinksOnly: true])
    default:
      break
    }
    
    // Always call the completion handler when done.
    completionHandler()
  }
}
