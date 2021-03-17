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
  @AppStorage("notificationsEnabled") var notificationsEnabled = false
  
  @AppStorage("allowDeploymentNotifications") var allowDeploymentNotifications = true
  @AppStorage("allowDeploymentErrorNotifications") var allowDeploymentErrorNotifications = true
  @AppStorage("allowDeploymentReadyNotifications") var allowDeploymentReadyNotifications = true
  
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
            }.padding(.vertical, 8)
            
            Button(action: {
              self.fetcher.settings.token = nil
              self.presentationMode.wrappedValue.dismiss()
              UIApplication.shared.unregisterForRemoteNotifications()
            }, label: {
              Text("logoutButton")
            }).foregroundColor(.systemRed)
          }
        }
        
        Section(header: Label("Notifications", systemImage: "bell.badge")) {
          Toggle("Enable Notifications", isOn: $notificationsEnabled)
            .toggleStyle(SwitchToggleStyle(tint: .accentColor))
            .onChange(of: notificationsEnabled, perform: { notificationsEnabled in
              NotificationManager.shared.toggleNotifications(on: notificationsEnabled, bindingTo: $notificationsEnabled)
            })
          
          Toggle(isOn: $allowDeploymentNotifications) {
            Label("New Builds", systemImage: "timer")
          }
          .toggleStyle(SwitchToggleStyle(tint: .accentColor))
          .disabled(!notificationsEnabled)
          
          Toggle(isOn: $allowDeploymentErrorNotifications) {
            Label("Build Errors", systemImage: "exclamationmark.triangle")
          }
          .toggleStyle(SwitchToggleStyle(tint: .accentColor))
          .disabled(!notificationsEnabled)
          
          Toggle(isOn: $allowDeploymentReadyNotifications) {
            Label("Deployment Ready", systemImage: "checkmark.circle")
          }
          .toggleStyle(SwitchToggleStyle(tint: .accentColor))
          .disabled(!notificationsEnabled)
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
