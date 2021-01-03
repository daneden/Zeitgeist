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
  @AppStorage(UDKey.showInDock.rawValue) var showInDock = true
  var horizontalSizeClass: SizeClassHack = .regular
  #else
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  #endif
  @State var selectedTeamID: String?
  @EnvironmentObject var fetcher: VercelFetcher
  
    var body: some View {
      List(selection: $selectedTeamID) {
        Section(header: Text("Teams")) {
          ForEach(fetcher.teams, id: \.id) { team in
            NavigationLink(
              destination: DeploymentsListView(teamID: team.id),
              tag: team.id,
              selection: $selectedTeamID
            ) {
              Label(team.name, systemImage: team.id == "-1" ? "person" : "person.2")
            }.tag(team.id)
          }
        }.onAppear {
          if self.selectedTeamID == nil && horizontalSizeClass == .regular {
            self.selectedTeamID = "-1"
          }
        }.onOpenURL(perform: { url in
          DispatchQueue.main.async {
            if case .deployment(let teamID, _) = url.detailPage {
              self.selectedTeamID = teamID
            }
          }
        })
        
        #if !os(macOS)
        NavigationLink(destination: SettingsView()) {
          Label("Settings", systemImage: "gearshape")
        }.isDetailLink(true).tag("settings")
        #else
        if !showInDock {
          Divider()
            .padding(.vertical, 8)
          VStack(spacing: 4) {
            HStack {
              Text("Preferences")
              Spacer()
              Text("⌘ ,")
            }
            
            HStack {
              Text("Quit")
              Spacer()
              Text("⌘Q")
            }
          }.font(.caption)
          .foregroundColor(.secondary)
        }
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
