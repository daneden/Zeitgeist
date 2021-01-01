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
  @AppStorage("showInDock") private var showInDock = false
  @AppStorage("showInMenuBar") private var showInMenuBar = false
  
  var statusBar: StatusBarController?
  let fetcher = VercelFetcher.shared
  var cancellable: AnyCancellable?
  
  func applicationDidBecomeActive(_ notification: Notification) {
    let app = NSApplication.shared
    
    if app.windows.filter({ $0.isResizable }).isEmpty {
      app.delegate?.application?(app, open: [URL(string: "zeitgeist://home")!])
    }
  }
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusBar = StatusBarController.init()
    
    if self.fetcher.settings.token != nil {
      fetcher.tick()
    }
    
    AppDelegate.updateDockPreference()
    AppDelegate.updateMenuBarPreference()
    
    cancellable = fetcher.$deploymentsStore.sink { deploymentStore in
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
        self.statusBar?.updateStatusBarIcon(withState: .error, forTeam: erroredPair.key)
      } else if let buildingPair = status.first(where: { (_, state) -> Bool in
        state == .building
      }) {
        self.statusBar?.updateStatusBarIcon(withState: .building, forTeam: buildingPair.key)
      } else {
        self.statusBar?.updateStatusBarIcon(withState: .ready)
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
  
  static func updateMenuBarPreference(_ showInMenuBar: Bool? = nil) {
    let showInMenuBar = UserDefaults.standard.bool(forKey: UDKey.showInMenuBar.rawValue)
    guard let delegate = NSApplication.shared.delegate as? AppDelegate else { return }
    if showInMenuBar {
      delegate.statusBar = StatusBarController.init()
    } else {
      delegate.statusBar = nil
    }
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
