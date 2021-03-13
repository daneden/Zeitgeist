//
//  MacOSSettingsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct MacOSSettingsView: View {
  var body: some View {
      AccountSettingsView()
        .fixedSize()
        .frame(minWidth: 300, minHeight: 100)
        .padding()
  }
}

struct AccountSettingsView: View {
  @EnvironmentObject var fetcher: VercelFetcher
  
  var body: some View {
    Form {
      Section {
        VStack {
          if let user: VercelUser = fetcher.user {
            HStack {
              VercelUserAvatarView(avatarID: user.avatar)
              
              VStack(alignment: .leading) {
                Text(user.name)
                
                Text(user.email)
                  .foregroundColor(.secondary)
                  .lineLimit(1)
              }
              
              Button(action: {
                self.fetcher.settings.token = nil
              }, label: {
                Text("logoutButton")
              }).foregroundColor(.systemRed)
            }
          } else {
            Text("Not signed in").font(.headline)
            Text("Sign in to Zeitgeist to see your deployments").foregroundColor(.secondary)
          }
        }
      }.padding(8)
    }
  }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(selectedTeam: "", presented: Binding(true)!)
//    }
//}
