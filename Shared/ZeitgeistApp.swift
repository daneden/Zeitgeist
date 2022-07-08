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
  
  @State private var confirmingDelete = false
  @StateObject var focusManager = FocusManager()
  
  static var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
  }
  
  var body: some Scene {
      WindowGroup {
          ContentView()
            .environmentObject(Session.shared)
            .environmentObject(focusManager)
            .alert(isPresented: $confirmingDelete) {
              Alert(
                title: Text("Confirm Deletion"),
                message: Text("Are you sure you want to delete this deployment?"),
                primaryButton: .destructive(Text("Delete Deployment"), action: {
                  if let deployment = selectedDeployment {
                    focusManager.action = .delete(deployment)
                  }
                }),
                secondaryButton: .cancel())
            }
      }
      .handlesExternalEvents(matching: ["main"])
      .commands {
        CommandGroup(replacing: CommandGroupPlacement.newItem) {}
        CommandGroup(replacing: CommandGroupPlacement.appVisibility) {}
        
        CommandMenu("Deployment") {
          Group {
            Button("Open Deployment") {
              selectedDeployment?.openDeploymentURL()
            }
            .keyboardShortcut("o", modifiers: [.command])

            Button("Open Logs") {
              selectedDeployment?.openLogsURL()
            }
            .keyboardShortcut("o", modifiers: [.command, .shift])

            Button("Copy URL") {
              selectedDeployment?.copyUrl()
            }
            .keyboardShortcut("c", modifiers: .command)

            Divider()

            if let deployment = selectedDeployment {
              if (deployment.state != .building && deployment.state != .queued) {
                Button("Delete Deployment") {
                  confirmingDelete = true
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
