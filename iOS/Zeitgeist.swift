//
//  Zeitgeist.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/06/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

typealias ZeitgeistButtonStyle = DefaultButtonStyle

@main
struct Zeitgeist: App {
  var settings: UserDefaultsManager
  var vercelNetwork: VercelFetcher
  
  init() {
    settings = UserDefaultsManager.shared
    vercelNetwork = VercelFetcher(settings)
  }
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(settings)
        .onAppear(perform: self.loadFetcherItems)
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
