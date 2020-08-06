//
//  ContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI
import Combine
#if os(macOS)
import Preferences
#endif


struct ContentView: View {
  @EnvironmentObject var settings: UserDefaultsManager
  #if os(macOS)
  var prefsViewController: PreferencesWindowController
  #endif
  @State var inputValue = ""
  
  var body: some View {
    Group {
      if self.settings.token == nil {
        LoginView()
      } else if let fetcher = VercelFetcher(settings, withTimer: true) {
        VStack(spacing: 0) {
          NavigationView {
            DeploymentsListView()
              .environmentObject(fetcher)
              .navigationTitle(Text("Deployments"))
              .frame(minWidth: 200, idealWidth: 300)
              .navigationBarItems(trailing: Group {
                #if os(iOS)
                NavigationLink(destination: SettingsView().environmentObject(fetcher)) {
                  Label("Settings", systemImage: "slider.horizontal.3").labelStyle(IconOnlyLabelStyle())
                }
                #endif
              })
            
            EmptyDeploymentView()
          }
          .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
          
          #if os(macOS)
          Divider()
          
          HStack {
            Spacer()
            Button(action: {
              prefsViewController.show()
            }) {
              Label("Settings", systemImage: "slider.horizontal.3")
            }

            Button(action: {
              self.quitApplication()
            }) {
              Label("Quit", systemImage: "escape")
            }
          }.padding(.horizontal).padding(.vertical, 8)
          #endif
        }
      }
    }
  }
  
  #if os(macOS)
  func quitApplication() {
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }
  #endif
}
