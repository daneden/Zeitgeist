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
  
  @StateObject var focusManager = FocusManager()
  
  static var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }
  
  var body: some Scene {
      WindowGroup {
          ContentView()
            .environmentObject(Session.shared)
            .environmentObject(focusManager)
      }
      .handlesExternalEvents(matching: ["main"])
      .commands {
        // TODO: Leverage @FocusedBinding and .focusSceneValue in the new SwiftUI APIs
        CommandMenu("Deployment") {
          Group {
            Button("Open Deployment") {
              if let url = selectedDeployment?.url {
                EnvironmentValues().openURL(url)
              }
            }
            .keyboardShortcut("o", modifiers: [.command])

            Button("Open Logs") {
              if let url = selectedDeployment?.url,
                 let logsUrl = URL(string: "\(url.absoluteString)/_logs"){
                EnvironmentValues().openURL(logsUrl)
              }
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Button("Copy URL") {
              print("copy url submitted")
            }
            .keyboardShortcut("c", modifiers: .command)

            Divider()

            if let deployment = selectedDeployment {
              if (deployment.state != .building && deployment.state != .queued) {
                Button("Delete Deployment") {
                  print("delete deployment submitted")
                }
                .keyboardShortcut(.delete, modifiers: .command)
              } else if (deployment.state == .building) {
                Button("Cancel Deployment") {
                  print("cancel deployment submitted")
                }
                .keyboardShortcut("c", modifiers: .control)
              }
            }
          }.disabled(!isDeploymentSelected)
        }
      }
  }
}

extension ZeitgeistApp {
  var isDeploymentSelected: Bool {
    guard let focusedElement = focusManager.focusedElement else {
      return false
    }
    
    switch focusedElement {
    case .deployment(_, _):
      return true
    case .account(_):
      return false
    }
  }
  
  var selectedDeployment: Deployment? {
    if case .deployment(let deployment, _) = focusManager.focusedElement {
      return deployment
    } else {
      return nil
    }
  }
}
