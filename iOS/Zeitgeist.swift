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
  var settings: UserDefaultsManager = UserDefaultsManager.shared
  var vercelNetwork: VercelFetcher = VercelFetcher.shared
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(settings)
        .environmentObject(vercelNetwork)
        .onAppear(perform: self.loadFetcherItems)
        .accentColor(.systemIndigo)
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
