//
//  HeaderView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct HeaderView: View {
  var fetchTeams = FetchVercelTeams()
  @State var teams: [VercelTeam] = [VercelTeam]()
  @EnvironmentObject var settings: UserDefaultsManager
  @State var selectedTeam: String = ""
  
  var body: some View {
    let chosenTeamId = Binding<String>(get: {
      self.selectedTeam
    }, set: {
      self.selectedTeam = $0
      self.updateSelectedTeam()
    })
    
    return VStack(alignment: .leading, spacing: 0) {
      if !teams.isEmpty {
        HStack {
          Spacer()
          Picker(selection: chosenTeamId, label: Text("")) {
            Text("Personal").tag("")
            ForEach(self.teams, id: \.id) {
              Text($0.name).tag($0.id)
            }
          }
          .id(self.teams.count)
          .fixedSize()
          .pickerStyle(SegmentedPickerStyle())
          .accessibility(label: Text("Team:"))
          Spacer()
        }.padding(8)
        Divider()
      }
    }.onReceive(self.fetchTeams.$response, perform: { val in
      if !val.teams.isEmpty {
        self.teams = val.teams
        if self.settings.currentTeam != nil {
          self.selectedTeam = self.settings.currentTeam!
        }
      }
    })
  }
  
  func updateSelectedTeam() {
    DispatchQueue.main.async {
      let team = self.selectedTeam.isEmpty ? nil : self.selectedTeam
      self.settings.currentTeam = team
    }
  }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView()
    }
}
