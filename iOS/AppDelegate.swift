//
//  AppDelegate.swift
//  iOS
//
//  Created by Daniel Eden on 16/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
  @AppStorage("notificationsEnabled") var notificationsEnabled = false
  
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    print("registering...")
    guard let userId = VercelFetcher.shared.user?.id else { return }
    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    let url = URL(string: "https://zeitgeist.link/api/registerPushNotifications?user_id=\(userId)&device_id=\(token)")!
    let request = URLRequest(url: url)
    
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      if let error = error {
        print(error)
        self.notificationsEnabled = false
      }
      
      if let _ = data {
        print("successfully registered for remote notifications")
        self.notificationsEnabled = true
      }
    }.resume()
  }
  
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    print(error.localizedDescription)
  }
}
