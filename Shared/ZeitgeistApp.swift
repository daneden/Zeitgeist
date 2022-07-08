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
  
  var body: some Scene {
    WindowGroup {
      
        TabView {
          NavigationView {
            Group {
              if Session.shared.accountId != nil {
                ProjectsListView()
              } else {
                PlaceholderView(forRole: .NoDeployments)
              }
            }
            .navigationTitle("Projects")
          }.tabItem {
            Label("Projects", systemImage: "folder")
          }
          
          NavigationView {
            Group {
              if let accountId = Session.shared.accountId {
                DeploymentListView(
                  accountId: accountId,
                  deploymentsSource: DeploymentsViewModel(accountId: accountId, autoload: true)
                )
              } else {
                PlaceholderView(forRole: .DeploymentList)
              }
            }.navigationTitle("Deployments")
          }
          .tabItem {
            Label("Deployments", systemImage: "list.bullet")
          }
        }
        .environmentObject(Session.shared)
    }
  }
}
