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
  
  init() {
    statusBar = NSStatusBar.system
    // Creating a status bar item having a fixed length
    statusItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)
    
    guard let statusBarButton = statusItem.button else { return }
    statusBarButton.image = NSImage(
      systemSymbolName: "arrowtriangle.up.circle.fill",
      accessibilityDescription: "Zeitgeist"
    )?.withSymbolConfiguration(.init(scale: .large))
    
    statusBarButton.image?.isTemplate = true
    statusBarButton.imagePosition = .imageLeft
    
    statusBarButton.action = #selector(mouseEventHandler(_:))
    statusBarButton.target = self
    
    statusBarButton.sendAction(on: [.rightMouseDown, .leftMouseDown])
  }
  
  @objc func mouseEventHandler(_ sender: NSStatusItem?) {
    let app = NSApplication.shared
    
    if app.windows.filter({ $0.isMainWindow }).isEmpty {
      app.delegate?.application?(NSApplication.shared, open: [URL(string: "zeitgeist://home")!])
    }
    
    app.activate(ignoringOtherApps: true)
  }
  
  func updateStatusBarIcon(withState state: DeploymentState, forTeam teamId: String? = nil) {
    if let button = statusItem.button {
      button.image = NSImage(
        systemSymbolName: statusImageMap[state] ?? "arrowtriangle.up.circle.fill",
        accessibilityDescription: "Zeitgeist"
      )?.withSymbolConfiguration(.init(scale: .large))
    }
  }
}
