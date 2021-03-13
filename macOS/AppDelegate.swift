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

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
  var statusBar: StatusBarController?
  let fetcher = VercelFetcher.shared
  var cancellable: AnyCancellable?
  var window: NSWindow!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    self.statusBar = .init()

    if self.fetcher.settings.token != nil {
      fetcher.tick()
    }

    cancellable = fetcher.deploymentsStore.$store.sink { [weak self] store in
      let reduction: [String: DeploymentState?] = store.reduce([:]) {
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

  func openPreferences() {
    window = NSWindow()
    window.styleMask = [.closable, .titled]
    window.title = "Preferences"
    window.contentView = NSHostingView(rootView: MacOSSettingsView().environmentObject(VercelFetcher.shared))
    window.delegate = self
    self.windowIsOpen = true

    window.makeKeyAndOrderFront(nil)
  }

  var windowIsOpen = false

  func windowWillClose(_ notification: Notification) {
    windowIsOpen = false
  }
}
