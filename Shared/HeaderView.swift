//
//  HeaderView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct HeaderView: View {
  @EnvironmentObject var fetcher: VercelFetcher
  @State var selectedTeam: String = ""
  @State var settingsShown = false
  
  var body: some View {
    let chosenTeamId = Binding<String>(get: {
      self.selectedTeam
    }, set: {
      self.selectedTeam = $0
      self.updateSelectedTeam()
    })
    
    return HStack {
      if !fetcher.teams.isEmpty {
        HStack {
          Spacer()
          Picker(selection: chosenTeamId, label: Text("")) {
            Text("Personal").tag("")
            ForEach(self.fetcher.teams, id: \.id) {
              Text($0.name).tag($0.id)
            }
          }
          .id(self.fetcher.teams.count)
          .fixedSize()
          .pickerStyle(SegmentedPickerStyle())
          .accessibility(label: Text("Team:"))
          Spacer()
        }
      }
      
      Spacer()
      
      Button(action: { self.settingsShown.toggle() }) {
        Label("Settings", systemImage: "gear").labelStyle(IconOnlyLabelStyle())
      }
      .buttonStyle(ZeitgeistButtonStyle())
      .popover(isPresented: $settingsShown) {
        VStack {
          Text("It's alive!")
          Button(action: {self.settingsShown.toggle()}) {
            Text("Close")
          }
        }
      }
    }.padding(.all, 8)
  }
  
  func updateSelectedTeam() {
    DispatchQueue.main.async {
      let team = self.selectedTeam.isEmpty ? nil : self.selectedTeam
      self.fetcher.teamId = team
    }
  }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        HeaderView()
      }
    }
}
