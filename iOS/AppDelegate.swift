//
//  AppDelegate.swift
//  iOS
//
//  Created by Daniel Eden on 08/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import UIKit
import BackgroundTasks

class AppDelegate: NSObject, UIApplicationDelegate {
  func applicationDidFinishLaunching(_ application: UIApplication) {
    BGTaskScheduler.shared.register(forTaskWithIdentifier: "me.daneden.Zeitgeist.fetchDeployments", using: nil) { (task) in
      self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
    }
  }
  
  func handleAppRefreshTask(task: BGAppRefreshTask) {
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    
    VercelFetcher.shared.loadDeployments()
    task.setTaskCompleted(success: true)
    
    scheduleBackgroundFetch()
  }
  
  func scheduleBackgroundFetch() {
    let fetchTask = BGAppRefreshTaskRequest(identifier: "me.daneden.Zeitgeist.fetchDeployments")
    fetchTask.earliestBeginDate = Date(timeIntervalSinceNow: 60)
    do {
      try BGTaskScheduler.shared.submit(fetchTask)
    } catch {
      print("Unable to submit task: \(error.localizedDescription)")
    }
  }
}
