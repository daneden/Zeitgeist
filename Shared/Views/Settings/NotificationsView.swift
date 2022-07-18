//
//  NotificationsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct NotificationsView: View {
  @AppStorage("notificationsEnabled") var notificationsEnabled = false
  @AppStorage("allowDeploymentNotifications") var allowDeploymentNotifications = true
  @AppStorage("allowDeploymentErrorNotifications") var allowDeploymentErrorNotifications = true
  @AppStorage("allowDeploymentReadyNotifications") var allowDeploymentReadyNotifications = true
  
  var body: some View {
    Form {
      Section {
        Group {
          Toggle("Enable Notifications", isOn: $notificationsEnabled)
          
          if notificationsEnabled {
            Toggle(isOn: $allowDeploymentNotifications) {
              DeploymentStateIndicator(state: .building)
            }
            
            Toggle(isOn: $allowDeploymentErrorNotifications) {
              DeploymentStateIndicator(state: .error)
            }
            
            Toggle(isOn: $allowDeploymentReadyNotifications) {
              DeploymentStateIndicator(state: .ready)
            }
          }
        }
      }
    }.navigationTitle("Notifications")
  }
}

struct NotificationsView_Previews: PreviewProvider {
  static var previews: some View {
    NotificationsView()
  }
}
