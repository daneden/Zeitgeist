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

@main
class AppDelegate: NSObject, NSApplicationDelegate {
  var popover = NSPopover.init()
  var statusBar: StatusBarController?
  let frame = NSSize(width: 680, height: 360)
  let settings = UserDefaultsManager.shared
  let fetcher = VercelFetcher.shared
  var cancellable: AnyCancellable?
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    let contentView = ContentView()
      .environmentObject(settings)
      .environmentObject(fetcher)
      .frame(width: frame.width, height: frame.height)
      .accentColor(.systemIndigo)
    
    popover.contentSize = NSSize(width: frame.width, height: frame.height)
    popover.contentViewController = NSHostingController(rootView: contentView)
    
    // Create the Status Bar Item with the above Popover
    statusBar = StatusBarController.init(popover)
    
    if settings.token != nil {
      fetcher.tick()
    }
    
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
}
