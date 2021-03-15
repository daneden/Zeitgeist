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
  @State var preferencesWindow: WindowViewController<AnyView>?
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
        Divider()
          .padding(.vertical, 8)
        VStack(alignment: .leading, spacing: 8) {
          Button(action: { openPreferences() }) {
            HStack {
              Label("Preferences", systemImage: "gearshape")
              Spacer()
            }
          }
          .buttonStyle(PlainButtonStyle())
          
          Button(action: { quitApplication() }) {
            HStack {
              Label("Quit", systemImage: "xmark.circle")
              Spacer()
            }
          }
          .buttonStyle(PlainButtonStyle())
          
        }
        #endif
        
      }
      .listStyle(PreferredListStyle())
      .navigationTitle(Text("Zeitgeist"))
    }
  
  #if os(macOS)
  func openPreferences() {
    if let window = self.preferencesWindow {
      window.showWindow(nil)
    } else {
      self.preferencesWindow = WindowViewController(rootView: AnyView(MacOSSettingsView().environmentObject(fetcher)))
      self.preferencesWindow?.window?.title = "Preferences"
      self.preferencesWindow?.showWindow(nil)
    }
  }
  
  func quitApplication() {
    NSApp.terminate(nil)
  }
  #endif
}

struct SidebarNavigation_Previews: PreviewProvider {
    static var previews: some View {
      SidebarNavigation()
    }
}
