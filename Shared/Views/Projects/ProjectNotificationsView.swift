//
//  ProjectNotificationsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 19/07/2022.
//

import SwiftUI

struct ProjectNotificationsView: View {
  var project: VercelProject
  
  @AppStorage("deploymentNotificationIds")
  private var deploymentNotificationIds: [VercelProject.ID] = []
  
  @AppStorage("deploymentErrorNotificationIds")
  private var deploymentErrorNotificationIds: [VercelProject.ID] = []
  
  @AppStorage("deploymentReadyNotificationIds")
  private var deploymentReadyNotificationIds: [VercelProject.ID] = []
  
  var body: some View {
    let allowDeploymentNotifications = Binding {
      deploymentNotificationIds.contains { $0 == project.id }
    } set: { deploymentNotificationIds.toggleElement(project.id, inArray: $0) }
    
    let allowDeploymentErrorNotifications = Binding {
      deploymentErrorNotificationIds.contains { $0 == project.id }
    } set: { deploymentErrorNotificationIds.toggleElement(project.id, inArray: $0) }
    
    let allowDeploymentReadyNotifications = Binding {
      deploymentReadyNotificationIds.contains { $0 == project.id }
    } set: { deploymentReadyNotificationIds.toggleElement(project.id, inArray: $0) }
    
    return Form {
      Section { } footer: {
        Text("Notification settings for \(project.name)")
      }
      Section {
        Toggle(isOn: allowDeploymentNotifications) {
          DeploymentStateIndicator(state: .building)
        }
        
        Toggle(isOn: allowDeploymentErrorNotifications) {
          DeploymentStateIndicator(state: .error)
        }
        
        Toggle(isOn: allowDeploymentReadyNotifications) {
          DeploymentStateIndicator(state: .ready)
        }
      }
    }.navigationTitle("Notifications")
  }
}

//struct ProjectNotificationsView_Previews: PreviewProvider {
//  static var previews: some View {
//    ProjectNotificationsView()
//  }
//}
