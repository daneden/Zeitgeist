//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/11/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine

enum UDKey: String {
  case showInDock, showInMenuBar
}

class AppDelegate: NSObject, NSApplicationDelegate {
  @AppStorage(UDKey.showInDock.rawValue) private var showInDock = true
  @AppStorage(UDKey.showInMenuBar.rawValue) private var showInMenuBar = true
  
  var statusBar: StatusBarController?
  let fetcher = VercelFetcher.shared
  var cancellable: AnyCancellable?
  
  func applicationWillBecomeActive(_ notification: Notification) {
    let app = NSApplication.shared
    let resizableWindows = app.windows.filter({ $0.isResizable })
    
    if resizableWindows.isEmpty {
      print("Found no active windows, opening a new one")
      app.delegate?.application?(app, open: [URL(string: "zeitgeist://home")!])
    } else if resizableWindows.count >= 2 {
      print("Found multiple windows, closing extras")
      for window in resizableWindows.suffix(resizableWindows.count - 1) {
        window.close()
      }
    }
  }
  
  func applicationWillResignActive(_ notification: Notification) {
    let app = NSApplication.shared
    let resizableWindows = app.windows.filter({ $0.isResizable })
    
    // Close windows when entering background if the app is running as agent
    if !showInDock {
      print("Entering background; closing windows")
      for window in resizableWindows {
        window.close()
      }
    }
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    if showInMenuBar {
      statusBar = StatusBarController()
    }
    
    if self.fetcher.settings.token != nil {
      fetcher.tick()
    }
    
    AppDelegate.updateDockPreference()
    
    cancellable = fetcher.$deploymentsStore.sink { [weak self] deploymentStore in
      let reduction: [String: DeploymentState?] = deploymentStore.store.reduce([:]) {
        let currentTeamID = $1.key
        let currentTeamDeployments = $1.value
        
        let latestState = currentTeamDeployments.first?.state
        
        return [currentTeamID: latestState]
      }
      
      let status = reduction.filter { (_, state) -> Bool in
        state == .error || state == .building
      }
      
      if let erroredPair = status.first(where: { (_, state) -> Bool in
        state == .error
      }) {
        self?.statusBar?.updateStatusBarIcon(withState: .error, forTeam: erroredPair.key)
      } else if let buildingPair = status.first(where: { (_, state) -> Bool in
        state == .building
      }) {
        self?.statusBar?.updateStatusBarIcon(withState: .building, forTeam: buildingPair.key)
      } else {
        self?.statusBar?.updateStatusBarIcon(withState: .ready)
      }
    }
  }
  
  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }
  
  static func updateDockPreference(_ showInDock: Bool? = nil) {
    let showInDock = UserDefaults.standard.bool(forKey: UDKey.showInDock.rawValue)

    NSApp.setActivationPolicy(showInDock ? .regular : .accessory)
    NSApp.activate(ignoringOtherApps: true)
  }
  
  static func updatePreference(key: UDKey, value: Any) {
    switch key {
    case .showInDock:
      guard let value = value as? Bool else { break }
      self.updateDockPreference(value)
    default:
      break
    }
  }
}
