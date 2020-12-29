//
//  StatusBarController.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/11/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import AppKit

let statusImageMap: [DeploymentState: String] = [
  .building: "arrow.triangle.2.circlepath.circle.fill",
  .error: "exclamationmark.circle.fill",
  .ready: "arrowtriangle.up.circle.fill"
]

class StatusBarController {
  private var statusBar: NSStatusBar
  private var statusItem: NSStatusItem
  private var popover: NSPopover
  private var eventMonitor: EventMonitor?
  private var timer: Timer = Timer()
  
  init(_ popover: NSPopover) {
    self.popover = popover
    
    statusBar = NSStatusBar.system
    // Creating a status bar item having a fixed length
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
    
    if let statusBarButton = statusItem.button {
      statusBarButton.image = NSImage(
        systemSymbolName: "arrowtriangle.up.circle.fill",
        accessibilityDescription: "Zeitgeist"
      )?.withSymbolConfiguration(.init(scale: .large))
      
      statusBarButton.image?.isTemplate = true
      statusBarButton.imagePosition = .imageLeft
      
      statusBarButton.action = #selector(togglePopover(sender:))
      statusBarButton.target = self
      
    }
    
    eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown], handler: mouseEventHandler)
  }
  
  @objc func togglePopover(sender: AnyObject) {
    if popover.isShown {
      hidePopover(sender)
    } else {
      showPopover(sender)
    }
  }
  
  func showPopover(_ sender: AnyObject) {
    if let statusBarButton = statusItem.button {
      popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
      eventMonitor?.start()
    }
  }
  
  func hidePopover(_ sender: AnyObject) {
    popover.performClose(sender)
    eventMonitor?.stop()
  }
  
  func mouseEventHandler(_ event: NSEvent?) {
    if popover.isShown {
      hidePopover(event!)
    }
  }
  
  func updateStatusBarIcon(withState state: DeploymentState, forTeam teamId: String? = nil) {
    if let button = self.statusItem.button {
      button.image = NSImage(
        systemSymbolName: statusImageMap[state] ?? "arrowtriangle.up.circle.fill",
        accessibilityDescription: "Zeitgeist"
      )?.withSymbolConfiguration(.init(scale: .large))
    }
  }
}
