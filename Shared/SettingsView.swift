//
//  FooterView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var settings: UserDefaultsManager
  @EnvironmentObject var fetcher: VercelFetcher
  @State var selectedTeam: String? = nil
  @State var presented = true
  
  var body: some View {
    let chosenTeamId = Binding<String>(get: {
      self.selectedTeam ?? self.fetcher.teamId ?? ""
    }, set: {
      self.selectedTeam = $0
      self.updateSelectedTeam()
    })
    
    return Form {
      if !fetcher.teams.isEmpty {
        Section {
          Picker(selection: chosenTeamId, label: Text("Selected Team")) {
            Text("Personal").tag("")
            ForEach(self.fetcher.teams, id: \.id) {
              Text($0.name).tag($0.id)
            }
          }
          .id(self.fetcher.teams.count)
          .accessibility(label: Text("Team:"))
        }
      }
      
      Section(header: Text("Current User")) {
        if let user: VercelUser = fetcher.user {
          HStack {
            Text(user.name)
            Spacer()
            Text(user.email)
              .foregroundColor(.secondary)
          }.padding(.vertical, 4)
        }
        
        Button(action: { self.settings.token = nil }) {
            Text("logoutButton")
        }.foregroundColor(Color(TColor.systemRed))
      }
      
    }
    .navigationTitle(Text("Settings"))
  }
  
  func updateSelectedTeam() {
    DispatchQueue.main.async {
      let team = self.selectedTeam?.isEmpty ?? true ? nil : self.selectedTeam
      self.fetcher.teamId = team
    }
  }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
      SettingsView(selectedTeam: "")
    }
}
