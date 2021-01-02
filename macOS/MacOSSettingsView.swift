//
//  MacOSSettingsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

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

struct AppearanceSettingsView: View {
  @AppStorage(UDKey.showInDock.rawValue) var showInDock = true
  @AppStorage(UDKey.showInMenuBar.rawValue) var showInMenuBar = true
  
  var body: some View {
    Form {
      Section {
        VStack(alignment: .leading) {
          Toggle(isOn: self.$showInDock) {
            Text("Show app icon in dock")
          }.disabled(!self.showInMenuBar)
          
          Toggle(isOn: self.$showInMenuBar) {
            Text("Show in menu bar")
          }.disabled(!self.showInDock)
          
          Divider().padding(.vertical, 8)
          
          Button(action: {
            self.quitApplication()
          }, label: {
            Text("Quit Zeitgeist")
          })
        }
      }.padding(8)
    }
    .onChange(of: showInDock) { showInDock in
      AppDelegate.updatePreference(key: .showInDock, value: showInDock)
    }
    .onChange(of: showInMenuBar) { _ in
      // Handled by Zeitgeist.swift
    }
  }
  
  func quitApplication() {
    DispatchQueue.main.async {
      NSApp.terminate(nil)
    }
  }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(selectedTeam: "", presented: Binding(true)!)
//    }
//}
