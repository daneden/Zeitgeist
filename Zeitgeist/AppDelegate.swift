//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Cocoa
import SwiftUI
import Reachability

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  
  var popover: NSPopover!
  var optionsMenu: NSMenu!
  var statusBarItem: NSStatusItem!
  var lastState: ZeitDeploymentState?
  var stateLastUpdated: Date?
  private var reachability: Reachability!
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let contentView = ContentView()
    let popover = NSPopover()
    let optionsMenu = NSMenu(title: "Zeitgeist Options")
    
    // MARK: Set up network monitoring
    do {
      try self.reachability = Reachability()
      NotificationCenter.default.addObserver(
        self,
        selector:#selector(self.reachabilityChanged),
        name: NSNotification.Name.reachabilityChanged,
        object: nil
      )
      try self.reachability.startNotifier()
    } catch (let error) {
    }
    
    // MARK: Set up options menu
    optionsMenu.delegate = self
    optionsMenu.addItem(NSMenuItem(title: "Quit Zeitgeist", action: #selector(self.terminateApp(_:)), keyEquivalent: "q"))
    
    // MARK: Set up Popover (Main UI)
    popover.contentSize = NSSize(width: 300, height: 500)
    popover.behavior = .transient
    popover.contentViewController = NSHostingController(rootView: contentView)
    
    self.popover = popover
    
    self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
    if let button = self.statusBarItem.button {
      button.image = NSImage(named: "menubarIcon")
      button.action = #selector(self.statusBarButtonClicked(_:))
      button.sendAction(on: [.leftMouseUp, .rightMouseUp])
      button.menu = optionsMenu
    }
    
    // Make the popover the key window so that it responds to clicks immediately
    self.popover.contentViewController?.view.window?.becomeKey()
    
    // Open the popover on initial application opening so that we can start fetching updates!
    self.togglePopover(nil)
  }
  
  @objc func terminateApp(_ sender: AnyObject?) {
    NSApplication.shared.terminate(self)
  }
  
  @objc func reachabilityChanged(note: Notification) {
    let reachability = note.object as! Reachability
    print(reachability.connection)
    switch reachability.connection {
    case .unavailable, .none:
      setIconBasedOnState(state: .offline)
      break
    default:
      setIconBasedOnState(state: .normal)
    }
  }
  
  func togglePopover(_ sender: AnyObject?) {
    if let button = self.statusBarItem.button {
      if self.popover.isShown {
        self.popover.performClose(sender)
      } else {
        self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
      }
    }
  }
  
  @objc func menuDidClose(_ menu: NSMenu) {
      statusBarItem.menu = nil // remove menu so button works as before
  }
  
  @objc func statusBarButtonClicked(_ sender: NSStatusBarButton) {
    let event = NSApp.currentEvent!

    if event.type == NSEvent.EventType.rightMouseUp {
      if let button = self.statusBarItem.button {
          button.menu?.popUp(positioning: nil, at: CGPoint(x: -1, y: button.bounds.maxY + 5), in: button)
      }
    } else {
      self.statusBarItem.menu = nil
      self.togglePopover(nil)
    }
  }
  
  func setIconBasedOnState(state: ZeitDeploymentState) {
    let currentTime = Date()
    
    if(state != self.lastState) {
      self.stateLastUpdated = currentTime
      self.lastState = state
    }
    
    switch state {
    case .building:
      self.statusBarItem.button?.image = NSImage(named: "menubarSyncing01")
      break
    case .ready:
      if(currentTime.timeIntervalSince(self.stateLastUpdated ?? currentTime) >= 5) {
        self.statusBarItem.button?.image = NSImage(named: "menubarIcon")
      } else {
        self.statusBarItem.button?.image = NSImage(named: "menubarSuccess")
      }
      break
    case .error:
      self.statusBarItem.button?.image = NSImage(named: "menubarError")
      break
    case .offline:
      self.statusBarItem.button?.image = NSImage(named: "menubarOffline")
    default:
      self.statusBarItem.button?.image = NSImage(named: "menubarIcon")
      break
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
}

