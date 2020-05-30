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
import Combine

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
  var popover: NSPopover!
  var settings = UserDefaultsManager()
  var optionsMenu: NSMenu!
  var statusBarItem: NSStatusItem!
  var lastState: ZeitDeploymentState?
  var stateLastUpdated: Date?
  var latestBuildUrl: String?
  var APP_VERSION: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  
  private var reachability: Reachability!
  private var iconAnimationTimer: Timer?
  private var animatedIconFrameCount = 0

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let contentView = ContentView().environmentObject(settings)
    let popover = NSPopover()
    let optionsMenu = NSMenu(title: NSLocalizedString("zeitgeistMenuTitle", comment: "Menu title"))

    // MARK: Set up network monitoring
    self.setupNetworking()

    // MARK: Set up options menu
    self.setupOptionsMenu(optionsMenu)

    // MARK: Set up Popover (Main UI)
    popover.contentSize = NSSize(width: 320, height: 512)
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
    guard let reachability = note.object as? Reachability else {
      return
    }
    switch reachability.connection {
    case .unavailable, .none:
      setIconBasedOnState(state: .offline)
    default:
      setIconBasedOnState(state: .normal)
    }
  }
  
  public func getAppVersion() -> String {
    return APP_VERSION
  }
  
  public func getVercelHeaders() -> [String: String] {
    return [
      "Authorization": "Bearer " + (settings.token ?? ""),
      "Content-Type": "application/json",
      "User-Agent": "Zeitgeist Client \(self.getAppVersion())"
    ]
  }
  
  func setupNetworking() {
    do {
      try self.reachability = Reachability()
      NotificationCenter.default.addObserver(
        self,
        selector: #selector(self.reachabilityChanged),
        name: NSNotification.Name.reachabilityChanged,
        object: nil
      )
      try self.reachability.startNotifier()
    } catch let error {
      print("Unable to initialise reachability: \(error)")
    }
  }
  
  func setupOptionsMenu(_ optionsMenu: NSMenu) {
    optionsMenu.delegate = self
    
    optionsMenu.addItem(
      withTitle: NSLocalizedString("runOnLogin", comment: "Run on login option"),
      action: #selector(self.openOnLogin(_:)),
      keyEquivalent: ""
    )
    
    optionsMenu.addItem(NSMenuItem.separator())
    
    optionsMenu.addItem(
      NSMenuItem(
        title: NSLocalizedString("quit", comment: "Quit Option"),
        action: #selector(self.terminateApp(_:)),
        keyEquivalent: "q"
      )
    )
  }

  func togglePopover(_ sender: AnyObject?) {
    if let button = self.statusBarItem.button {
      if self.popover.isShown {
        self.popover.performClose(sender)
      } else {
        self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        self.popover.contentViewController?.view.window?.becomeKey()
      }
    }
  }
  
  @objc func openOnLogin(_ sender: AnyObject?) {
    NSWorkspace.shared.open(URL(string: "https://support.apple.com/en-gb/guide/mac-help/mh15189/mac")!)
  }
  
  @objc func openLatestVersionUrl(_ sender: AnyObject?) {
    NSWorkspace.shared.open(URL(string: self.latestBuildUrl!)!)
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

    if state != self.lastState {
      self.stateLastUpdated = currentTime
      self.lastState = state
    }

    if state != .building {
      self.enqueueBuildingIconAnimation(isAnimating: false)
    }

    self.statusBarItem.button?.toolTip = String(
      format: NSLocalizedString(
        "menubarTitle",
        comment: "Title that appears when hovering over the menu bar icon"
      ),
      "\(state)"
    )

    switch state {
    case .building:
      self.enqueueBuildingIconAnimation(isAnimating: true)
    case .error:
      self.statusBarItem.button?.image = NSImage(named: "menubarError")
    case .offline:
      self.statusBarItem.button?.image = NSImage(named: "menubarOffline")
    case .ready:
      if currentTime.timeIntervalSince(self.stateLastUpdated ?? currentTime) >= 5 {
        self.statusBarItem.button?.image = NSImage(named: "menubarIcon")
      } else {
        self.statusBarItem.button?.image = NSImage(named: "menubarSuccess")
      }
    default:
      self.statusBarItem.button?.image = NSImage(named: "menubarIcon")
    }
  }

  func enqueueBuildingIconAnimation(isAnimating: Bool) {
    if self.iconAnimationTimer != nil && isAnimating {
      return
    }

    if isAnimating {
      let icons = [
        NSImage(named: "menubarSyncing01"),
        NSImage(named: "menubarSyncing02"),
        NSImage(named: "menubarSyncing03"),
        NSImage(named: "menubarSyncing04"),
        NSImage(named: "menubarSyncing05"),
        NSImage(named: "menubarSyncing06"),
        NSImage(named: "menubarSyncing07"),
        NSImage(named: "menubarSyncing08"),
        NSImage(named: "menubarSyncing09"),
        NSImage(named: "menubarSyncing10"),
        NSImage(named: "menubarSyncing11"),
        NSImage(named: "menubarSyncing12")
      ]

      func callback() {
        self.statusBarItem.button?.image = icons[self.animatedIconFrameCount % (icons.count - 1)]
        self.animatedIconFrameCount += 1
      }

      self.iconAnimationTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
        callback()
      }

      callback()
    } else {
      self.iconAnimationTimer?.invalidate()
      self.iconAnimationTimer = nil
    }

    return
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
}
