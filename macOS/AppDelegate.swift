//
//  AppDelegate.swift
//  macOS
//
//  Created by Daniel Eden on 02/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Cocoa
import SwiftUI
import Preferences

class AppDelegate: NSObject, NSApplicationDelegate {
  var popover: NSPopover!
  var statusBarItem: NSStatusItem!
  var mainView: ContentView?
  
  lazy var preferences: [PreferencePane] = [ZeitgeistPreferencesViewController()]
  lazy var preferencesWindowController = PreferencesWindowController(
    preferencePanes: preferences,
    style: .toolbarItems,
    animated: true,
    hidesToolbarForSingleItem: true
  )
  
  func applicationDidFinishLaunching(_ notification: Notification) {
    print("Launched application")
    
    let settings = UserDefaultsManager()
    let fetcher = VercelFetcher(settings)
    let view = ContentView(prefsViewController: preferencesWindowController).environmentObject(settings).environmentObject(fetcher)
    
    let popover = NSPopover()
    popover.contentSize = NSSize(width: 680, height: 460)
    popover.behavior = .transient
    popover.contentViewController = NSHostingController(rootView: view)
    
    self.popover = popover
    
    self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
    
    if let button = self.statusBarItem.button {
      button.image = NSImage(named: "zeitgeist-menu-bar")
      button.action = #selector(togglePopover(_:))
      self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
    }
  }
  
  @objc func togglePopover(_ sender: AnyObject?) {
    if let button = self.statusBarItem.button {
      if self.popover.isShown {
        self.popover.performClose(sender)
      } else {
        self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        self.popover.contentViewController?.view.window?.makeKey()
      }
    }
  }
}
