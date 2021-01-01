//
//  FooterView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  @EnvironmentObject var fetcher: VercelFetcher
  @Environment(\.presentationMode) var presentationMode
  
  var body: some View {
    Form {
      if fetcher.settings.token == nil {
        VStack(alignment: .leading) {
          Text("Not signed in").font(.headline)
          Text("Sign in to Zeitgeist to see your deployments").foregroundColor(.secondary)
        }.padding()
      } else {
        Section(header: Label("Current User", systemImage: "person")) {
          if let user: VercelUser = fetcher.user {
            HStack {
              VercelUserAvatarView(avatarID: user.avatar)
              
              VStack(alignment: .leading) {
                Text(user.name)
                
                Text(user.email)
                  .foregroundColor(.secondary)
                  .lineLimit(1)
              }
            }
          }
        }
        
        Section {
          Button(action: {
            self.fetcher.settings.token = nil
            self.presentationMode.wrappedValue.dismiss()
          }, label: {
            Text("logoutButton")
          }).foregroundColor(.systemRed)
        }
      }
    }
    .navigationTitle(Text("Settings"))
  }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(selectedTeam: "", presented: Binding(true)!)
//    }
//}
