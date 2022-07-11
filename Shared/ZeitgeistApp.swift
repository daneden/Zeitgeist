//
//  ZeitgesitApp.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

@main
struct ZeitgeistApp: App {
#if !os(macOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#else
  @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
#endif
  
  static var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }
  
  @StateObject var session = VercelSession()
  
  var body: some Scene {
    WindowGroup {
      Group {
        if session.isAuthenticated {
          AuthenticatedContentView()
        } else {
          // Non-authenticated view
        }
      }
      .onAppear {
        if let accountId = Preferences.authenticatedAccountIds.first {
          session.accountId = accountId
        }
      }
      .environmentObject(session)
    }
  }
}
