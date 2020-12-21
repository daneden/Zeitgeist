//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/11/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  var popover = NSPopover.init()
  var statusBar: StatusBarController?
  let frame = NSSize(width: 680, height: 360)
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let settings = UserDefaultsManager.shared
    let fetcher = VercelFetcher.shared
    
    let contentView = ContentView()
      .environmentObject(settings)
      .environmentObject(fetcher)
      .frame(width: frame.width, height: frame.height)
    
    popover.contentSize = NSSize(width: frame.width, height: frame.height)
    popover.contentViewController = NSHostingController(rootView: contentView)
    
    // Create the Status Bar Item with the above Popover
    statusBar = StatusBarController.init(popover)
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
}
