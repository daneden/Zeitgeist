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
  #if os(macOS)
  var horizontalSizeClass: SizeClassHack = .regular
  #else
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  #endif
  @State var settingsVisible = false
  @State var selection: String?
  @EnvironmentObject var fetcher: VercelFetcher
  
    var body: some View {
      List(selection: $selection) {
        Section(header: Text("Teams")) {
          NavigationLink(
            destination: DeploymentsListView(),
            tag: "-1",
            selection: $selection
          ) {
            Label("Personal", systemImage: "person")
          }
          
          ForEach(fetcher.teams, id: \.id) { team in
            NavigationLink(
              destination: DeploymentsListView(team: team),
              tag: team.id,
              selection: $selection
            ) {
              Label(team.name, systemImage: "person.2")
            }.tag(team.id)
          }
        }.onAppear {
          if self.selection == nil && horizontalSizeClass == .regular {
            self.selection = "-1"
          }
        }
        
        #if !os(macOS)
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
      SidebarNavigation()
    }
}
