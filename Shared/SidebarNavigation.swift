//
//  SidebarNavigation.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 20/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

#if os(macOS)
typealias PreferredListStyle = SidebarListStyle
#else
typealias PreferredListStyle = GroupedListStyle
#endif

struct SidebarNavigation: View {
  @State var settingsVisible = false
  @Binding var selection: String?
  @EnvironmentObject var fetcher: VercelFetcher
  
    var body: some View {
      List(selection: $selection) {
        Section(header: Text("Teams")) {
          NavigationLink(destination: DeploymentsListView()) {
            Label("Personal", systemImage: "person")
          }.tag("-1")
          
          ForEach(fetcher.teams, id: \.id) { team in
            NavigationLink(destination: DeploymentsListView(team: team)) {
              Label(team.name, systemImage: "person.2")
            }.tag(team.id)
          }
        }
        
        #if os(macOS)
        Divider()
        
        HStack {
          Label("Settings", systemImage: "gearshape")
        }.onTapGesture {
          self.settingsVisible.toggle()
        }.popover(isPresented: $settingsVisible) {
          SettingsView().padding()
        }
        #else
        NavigationLink(destination: SettingsView()) {
          Label("Settings", systemImage: "gearshape")
        }.tag("settings")
        #endif
        
      }
      .listStyle(PreferredListStyle())
      .navigationTitle(Text("Zeitgeist"))
      
    }
}

struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
      SidebarNavigation(selection: .constant("-1"))
    }
}
