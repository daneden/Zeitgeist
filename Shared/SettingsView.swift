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
  
  var body: some View {
    Form {
      if settings.token == nil {
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
        
        #if os(macOS)
        Divider().padding(.vertical, 8)
        #endif
        
        Section {
          Button(action: {
            self.settings.token = nil
          }, label: {
            Text("logoutButton")
          }).foregroundColor(.systemRed)
          
          #if os(macOS)
          Button(action: {
            self.quitApplication()
          }, label: {
            Text("Quit Zeitgeist")
          })
          #endif
        }
      }
    }
    .navigationTitle(Text("Settings"))
  }
  
  #if os(macOS)
  func quitApplication() {
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }
  #endif
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(selectedTeam: "", presented: Binding(true)!)
//    }
//}
