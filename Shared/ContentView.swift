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
  
  var body: some View {
    Group {
      if self.settings.token == nil {
        LoginView()
      } else if let fetcher = VercelFetcher(settings, withTimer: true) {
        NavigationView {
          DeploymentsListView()
            .environmentObject(fetcher)
            .navigationTitle(Text("Deployments"))
            .frame(minWidth: 200, idealWidth: 300)
            .toolbar {
              #if os(iOS)
              ToolbarItem {
                NavigationLink(destination: SettingsView()) {
                  Label("Settings", systemImage: "slider.horizontal.3").labelStyle(IconOnlyLabelStyle())
                }
              }
              #else
              ToolbarItem {
                EmptyView()
              }
              #endif
            }
          
          EmptyDeploymentView()
        }
        .frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
