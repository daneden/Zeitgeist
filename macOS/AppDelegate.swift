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
  var preferencesWindow: NSWindow!
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let settings = UserDefaultsManager.shared
    let fetcher = VercelFetcher.shared
    
    let contentView = ContentView().environmentObject(settings).environmentObject(fetcher)
    
    // Set the SwiftUI's ContentView to the Popover's ContentViewController
    popover.contentViewController = MainViewController()
    popover.contentSize = NSSize(width: 600, height: 360)
    popover.contentViewController = NSHostingController(rootView: contentView)
    
    // Create the Status Bar Item with the above Popover
    statusBar = StatusBarController.init(popover)
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  @objc func openPreferencesWindow() {
    if nil == preferencesWindow {
      let preferencesView = SettingsView().padding()
      
      // Create the preferences window and set content
      preferencesWindow = NSWindow(
        contentRect: NSRect(x: 0, y: 0, width: 360, height: 300),
        styleMask: [.titled, .closable, .fullSizeContentView],
        backing: .buffered,
        defer: false)
      preferencesWindow.center()
      preferencesWindow.title = "Zeitgeist Settings"
      preferencesWindow.isReleasedWhenClosed = false
      preferencesWindow.contentView = NSHostingView(rootView: preferencesView)
    }
    NSApp.activate(ignoringOtherApps: true)
    preferencesWindow.makeKeyAndOrderFront(nil)
  }
}

