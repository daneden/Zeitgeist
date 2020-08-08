//
//  Preferences.swift
//  macOS
//
//  Created by Daniel Eden on 02/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI
import Preferences

extension Preferences.PaneIdentifier {
  static let general = Self("general")
}

let ZeitgeistPreferencesViewController: () -> PreferencePane = {
  let paneView = Preferences.Pane(
    identifier: .general, title: "Preferences", toolbarIcon: NSImage(named: NSImage.preferencesGeneralName)!
  ) {
    PrefPane()
  }
  
  return Preferences.PaneHostingController(pane: paneView)
}

struct PrefPane: View {
  var settings: UserDefaultsManager
  var vercelNetwork: VercelFetcher
  
  init() {
    settings = UserDefaultsManager.shared
    vercelNetwork = VercelFetcher.shared
  }
  
  var body: some View {
    SettingsView()
      .frame(width: 360)
      .padding()
      .environmentObject(settings)
      .environmentObject(vercelNetwork)
      .onAppear(perform: self.loadFetcherItems)
      .onReceive(self.settings.objectWillChange) {
        self.loadFetcherItems()
      }
  }
  
  func loadFetcherItems() {
    if vercelNetwork.settings.token != nil {
      vercelNetwork.loadUser()
      vercelNetwork.loadTeams()
      vercelNetwork.loadDeployments()
    }
  }
}
