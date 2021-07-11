//
//  NotificationsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct NotificationsView: View {
  @AppStorage("activeSupporterSubscription") var activeSubscription = false
  @AppStorage("notificationsEnabled") var notificationsEnabled = false
  @AppStorage("allowDeploymentNotifications") var allowDeploymentNotifications = true
  @AppStorage("allowDeploymentErrorNotifications") var allowDeploymentErrorNotifications = true
  @AppStorage("allowDeploymentReadyNotifications") var allowDeploymentReadyNotifications = true
  
  var body: some View {
    Form {
      if !activeSubscription {
        SupporterPromoView()
      }
      
      Section {
        Group {
          Toggle("Enable Notifications", isOn: $notificationsEnabled)
            .onChange(of: notificationsEnabled, perform: { notificationsEnabled in
              NotificationManager.shared.toggleNotifications(on: notificationsEnabled, bindingTo: $notificationsEnabled)
            })
          
          Group {
            Toggle(isOn: $allowDeploymentNotifications) {
              Label("New Builds", systemImage: "timer")
            }
            
            Toggle(isOn: $allowDeploymentErrorNotifications) {
              Label("Build Errors", systemImage: "exclamationmark.triangle")
            }
            
            Toggle(isOn: $allowDeploymentReadyNotifications) {
              Label("Deployment Ready", systemImage: "checkmark.circle")
            }
          }
          .disabled(!notificationsEnabled)
        }
        .disabled(!activeSubscription)
        .opacity(activeSubscription ? 1.0 : 0.35)
      }
    }.navigationTitle("Notifications")
  }
}

struct NotificationsView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationsView()
  }
}
