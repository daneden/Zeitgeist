//
//  FooterView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//
// swiftlint:disable multiple_closures_with_trailing_closure

import SwiftUI

#if os(macOS)
typealias SettingsContainer = Group
#else
typealias SettingsContainer = NavigationView
#endif

struct SettingsView: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var settings: UserDefaultsManager = UserDefaultsManager.shared
  @ObservedObject var fetcher: VercelFetcher = VercelFetcher.shared
  @State var selectedTeam: String?
  
  var body: some View {
    let chosenTeamId = Binding<String>(get: {
      self.selectedTeam ?? self.settings.currentTeam ?? self.fetcher.teamId ?? ""
    }, set: {
      self.selectedTeam = $0
      self.updateSelectedTeam()
    })
    
    return SettingsContainer {
      Form {
        if settings.token == nil {
          VStack(alignment: .leading) {
            Text("Not signed in").font(.headline)
            Text("Sign in to Zeitgeist to see your deployments").foregroundColor(.secondary)
          }.padding()
        } else {
          Section(header: Text("Current User")) {
            if let user: VercelUser = fetcher.user {
              HStack {
                Text(user.name)
                  .lineLimit(2)
                Spacer()
                Text(user.email)
                  .foregroundColor(.secondary)
                  .fixedSize()
                  .lineLimit(1)
              }.padding(.vertical, 4)
            }
            
            if !fetcher.teams.isEmpty {
              #if os(macOS)
              Divider().padding(.vertical, 16)
              #endif
              
              Picker(selection: chosenTeamId, label: Text("Selected Team")) {
                Text("Personal").tag("")
                ForEach(self.fetcher.teams, id: \.id) {
                  Text($0.name).tag($0.id)
                }
              }
            }
          }
          
          #if os(macOS)
          Divider().padding(.vertical, 8)
          #endif
          
          Section {
            Button(action: {
              self.settings.token = nil
              self.presentationMode.wrappedValue.dismiss()
            }) {
              Text("logoutButton")
            }.foregroundColor(Color(TColor.systemRed))
          }
        }
      }
      .navigationTitle(Text("Settings"))
      .onAppear {
        fetcher.loadUser()
        fetcher.loadTeams()
      }
      .toolbar(content: {
        ToolbarItem {
          Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
            Text("Close")
          }
        }
      })
    }
  }
  
  func updateSelectedTeam() {
    DispatchQueue.main.async {
      let team = self.selectedTeam?.isEmpty ?? true ? nil : self.selectedTeam
      self.fetcher.teamId = team
      self.settings.currentTeam = team
      self.fetcher.loadDeployments()
    }
  }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(selectedTeam: "", presented: Binding(true)!)
//    }
//}
