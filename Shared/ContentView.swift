//
//  ContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
  @EnvironmentObject var settings: UserDefaultsManager
  @State var inputValue = ""
  @State var settingsPresented = false
  
  var body: some View {
    VStack(spacing: 0) {
      if self.settings.token == nil {
        LoginView()
      } else if let fetcher = VercelFetcher(settings, withTimer: true) {
        NavigationView {
          DeploymentsListView()
            .environmentObject(fetcher)
            .navigationTitle(Text("Deployments"))
            .frame(minWidth: 200, idealWidth: 300)
            .toolbar {
              ToolbarItem {
                Button(action: { self.settingsPresented.toggle() }) {
                  Label("Settings", systemImage: "slider.horizontal.3").labelStyle(IconOnlyLabelStyle())
                }.sheet(isPresented: $settingsPresented, content: {
                  SettingsView()
                    .environmentObject(fetcher)
                    .environmentObject(settings)
                })
              }
            }
          
          EmptyDeploymentView()
        }.sheet(isPresented: $settingsPresented) {
          SettingsView()
        }
        
        #if os(macOS)
        Divider()
        
        HStack {
          Spacer()
          Button(action: {
            NSApp.sendAction(#selector(AppDelegate.openPreferencesWindow), to: nil, from:nil)
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
    .accentColor(Color(TColor.systemIndigo))
  }
  
  #if os(macOS)
  func quitApplication() {
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }
  #endif
}
