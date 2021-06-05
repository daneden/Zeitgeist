//
//  VerdantApp.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

@main
struct VerdantApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
      WindowGroup {
          ContentView()
            .environmentObject(Session.shared)
      }
  }
}
