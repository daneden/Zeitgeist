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
  @State private var initialising = true
  
  var body: some Scene {
    WindowGroup {
      Group {
        if initialising {
          ProgressView()
        } else {
          if session.isAuthenticated {
            AuthenticatedContentView()
          } else {
            OnboardingView()
          }
        }
      }
      .symbolRenderingMode(.hierarchical)
      .onAppear {
        withAnimation {
          if let account = Preferences.accounts.first {
            session.account = account
          }
          
          initialising = false
        }
      }
      .environmentObject(session)
    }
  }
}
