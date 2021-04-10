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
  @Environment(\.deeplink) var deeplink
  
  #if os(macOS)
  var horizontalSizeClass: SizeClassHack = .regular
  @State var preferencesWindow: WindowViewController<AnyView>?
  #else
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  #endif
  @State var selectedTeamID: String?
  @EnvironmentObject var session: Session
  
    var body: some View {
      List(selection: $selectedTeamID) {
        Section(header: Text("Accounts")) {
          ForEach(session.fetchers, id: \.account.id) { fetcher in
            NavigationLink(
              destination: DeploymentsListView(),
              tag: fetcher.account.id,
              selection: $selectedTeamID
            ) {
              Label(fetcher.account.name ?? "Personal", systemImage: fetcher.account.isTeam ? "person.2" : "person")
            }
          }
        }.onChange(of: deeplink) { deeplink in
          if case .deployment(let teamId, _) = deeplink {
            session.selectedAccount = teamId
          }
        }
        
        #if !os(macOS)
        NavigationLink(destination: SettingsView()) {
          Label("Settings", systemImage: "gearshape")
        }.isDetailLink(true).tag("settings")
        #else
        Divider()
          .padding(.vertical, 8)
        VStack(alignment: .leading, spacing: 8) {
          Button(action: { openPreferences() }, label: {
            HStack {
              Label("Preferences", systemImage: "gearshape")
              Spacer()
            }
          })
          .buttonStyle(PlainButtonStyle())
          
          Button(action: { quitApplication() }, label: {
            HStack {
              Label("Quit", systemImage: "xmark.circle")
              Spacer()
            }
          })
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
