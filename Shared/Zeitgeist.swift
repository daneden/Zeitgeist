//
//  Zeitgeist.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/06/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

#if os(macOS)
typealias ZeitgeistButtonStyle = LinkButtonStyle
#else
typealias ZeitgeistButtonStyle = DefaultButtonStyle
#endif

@main
struct Zeitgeist: App {
  var settings: UserDefaultsManager
  var vercelNetwork: VercelFetcher
  
  init() {
    settings = UserDefaultsManager()
    vercelNetwork = VercelFetcher(settings)
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(settings)
        .environmentObject(vercelNetwork)
        .frame(idealWidth: 680, maxWidth: .infinity, idealHeight: 460, maxHeight: .infinity)
        .onAppear(perform: self.loadFetcherItems)
    }
    
    #if os(macOS)
    Settings {
      SettingsView()
        .frame(width: 400)
        .padding()
        .environmentObject(settings)
        .environmentObject(vercelNetwork)
        .onAppear(perform: self.loadFetcherItems)
        .onReceive(self.settings.objectWillChange) {
          self.loadFetcherItems()
        }
    }
    #endif
  }
  
  func loadFetcherItems() {
    if vercelNetwork.settings.token != nil {
      vercelNetwork.loadUser()
      vercelNetwork.loadTeams()
      vercelNetwork.loadDeployments()
    }
  }
}
