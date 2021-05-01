//
//  FooterView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.session) var session
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.deeplink) var deeplink
  
  @AppStorage(UDValues.activeSupporterSubscription) var activeSubscription
  @AppStorage(UDValues.notificationsEnabled) var notificationsEnabled
  @AppStorage(UDValues.allowDeploymentNotifications) var allowDeploymentNotifications
  @AppStorage(UDValues.allowDeploymentErrorNotifications) var allowDeploymentErrorNotifications
  @AppStorage(UDValues.allowDeploymentReadyNotifications) var allowDeploymentReadyNotifications
  
  @State var addAccountSheetPresented = false
  
  #if os(iOS)
  @ObservedObject var iapHelper = IAPHelper.shared
  #endif
  
  var body: some View {
    Form {
      if session?.accounts.isEmpty == true {
        VStack(alignment: .leading) {
          Text("Not signed in").font(.headline)
          Text("Sign in to Zeitgeist to see your deployments").foregroundColor(.secondary)
        }.padding()
      } else {
        Section(header: Label("Accounts", systemImage: "person.2")) {
          if let accountKeys = session?.accounts.keys, let accounts = Array(accountKeys) {
            ForEach(accounts, id: \.self) { account in
              UserListRow(userId: account)
            }
          }
          
          Button(action: { addAccountSheetPresented = true }) {
            Label("Add Account", systemImage: "plus.circle")
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
      
      session?.current?.loadUser()
    }
    .sheet(isPresented: $addAccountSheetPresented) {
      LoginView()
    }
    .onChange(of: session?.accounts) { newValue in
      if newValue?.isEmpty == true {
        self.presentationMode.wrappedValue.dismiss()
      }
    }
  }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//      SettingsView(selectedTeam: "", presented: Binding(true)!)
//    }
//}
