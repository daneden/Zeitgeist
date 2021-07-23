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
  #endif
  
  var body: some Scene {
      WindowGroup {
          ContentView()
            .environmentObject(Session.shared)
      }.commands {
        // TODO: Leverage @FocusedBinding and .focusSceneValue in the new SwiftUI APIs
//        CommandMenu("Deployment") {
//          Button("Open Deployment") {
//            print("open deployment submitted")
//          }
//          .keyboardShortcut("o", modifiers: [.command])
//
//          Button("Open Logs") {
//            print("open logs submitted")
//          }
//          .keyboardShortcut("o", modifiers: [.command, .shift])
//
//          Button("Copy URL") {
//            print("copy url submitted")
//          }
//          .keyboardShortcut("c", modifiers: .command)
//
//          Divider()
//
//          Button("Delete Deployment") {
//            print("delete deployment submitted")
//          }
//          .keyboardShortcut(.delete, modifiers: .command)
//
//          Button("Cancel Deployment") {
//            print("cancel deployment submitted")
//          }
//          .keyboardShortcut("c", modifiers: .control)
//        }
      }
  }
}
