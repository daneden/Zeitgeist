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
  #if os(macOS)
  // swiftlint:disable weak_delegate
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  #else
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @State var showInMenuBar = true
  #endif
  var vercelNetwork: VercelFetcher = VercelFetcher.shared
  @Environment(\.scenePhase) var scenePhase
  
  var body: some Scene {
    WindowGroup {
      ContentView()
        .environmentObject(vercelNetwork)
        .onAppear(perform: self.loadFetcherItems)
        .accentColor(Color("AccentColor"))
    }.commands {
      CommandGroup(replacing: .newItem, addition: {})
      SidebarCommands()
      ToolbarCommands()
    }
    .handlesExternalEvents(matching: ["*"])
  }
  
  func loadFetcherItems() {
    if vercelNetwork.settings.token != nil {
      vercelNetwork.tick()
    }
  }
}

enum TabIdentifier: Hashable {
  case home, settings, deploymentDetail, team
}

extension URL {
  var isDeeplink: Bool {
    return scheme == "zeitgeist" // matches my-url-scheme://<rest-of-the-url>
  }

  var tabIdentifier: TabIdentifier? {
    guard isDeeplink else { return nil }

    switch host {
    case "home": return .home
    case "settings": return .settings
    case "deployment": return .deploymentDetail
    case "team": return .team
    default: return nil
    }
  }
}

enum PageIdentifier: Hashable {
  case deployment(team: String, id: String)
}

extension URL {
  // Deployment pages are linked by zeitgeist://deployment/{teamID}/{deploymentID}
  var detailPage: PageIdentifier? {
    guard let tabIdentifier = tabIdentifier, pathComponents.count > 2 else {
      return nil
    }

    switch tabIdentifier {
    case .deploymentDetail: return .deployment(team: pathComponents[1], id: pathComponents[2])
    default: return nil
    }
  }
}
