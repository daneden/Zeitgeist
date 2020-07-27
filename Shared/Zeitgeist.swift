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

var APP_VERSION: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

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
      ContentView().environmentObject(settings).environmentObject(vercelNetwork).frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}
