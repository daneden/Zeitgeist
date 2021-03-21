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
  @Environment(\.deeplink) var deeplink
  
  @AppStorage(UDValues.activeSupporterSubscription) var activeSubscription
  @AppStorage(UDValues.notificationsEnabled) var notificationsEnabled
  @AppStorage(UDValues.allowDeploymentNotifications) var allowDeploymentNotifications
  @AppStorage(UDValues.allowDeploymentErrorNotifications) var allowDeploymentErrorNotifications
  @AppStorage(UDValues.allowDeploymentReadyNotifications) var allowDeploymentReadyNotifications
  
  #if os(iOS)
  @ObservedObject var iapHelper = IAPHelper.shared
  #endif
  
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
              #if os(iOS)
              UIApplication.shared.unregisterForRemoteNotifications()
              #endif
            }, label: {
              Text("logoutButton")
            }).foregroundColor(.systemRed)
          }
        }
        
        #if os(iOS)
        Section(
          header: Label("Notifications", systemImage: notificationsEnabled ? "bell.badge" : "bell.slash")
        ) {
          Group {
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
          .disabled(!activeSubscription)
          .opacity(activeSubscription ? 1.0 : 0.35)
          
          if !activeSubscription {
            SupporterPromoView()
          }
        }
        .transition(.slide)
        
        if activeSubscription {
          Section(header: Label("Supporter Subscription", systemImage: "heart")) {
            ForEach(iapHelper.activeSubscriptions, id: \.productIdentifier) { product in
              VStack(alignment: .leading) {
                Text("Current Subscription")
                  .font(.caption)
                  .foregroundColor(.secondary)
                
                HStack {
                  Text(product.localizedTitle)
                  
                  Spacer()
                  
                  Text(product.localizedPrice)
                    .foregroundColor(.secondary)
                }
              }
            }
            Button(action: { UIApplication.openSubscriptionManagement() }, label: {
              Text("Manage in App Store")
            })
          }
        }
        #endif
      }
    }
    .navigationTitle(Text("Settings"))
    .onAppear {
      #if os(iOS)
      IAPHelper.shared.refresh()
      #endif
    }
  }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(selectedTeam: "", presented: Binding(true)!)
//    }
//}
