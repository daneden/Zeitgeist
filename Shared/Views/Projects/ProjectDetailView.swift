//
//  ProjectDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI

struct ProjectDetailView: View {
  @EnvironmentObject var session: VercelSession
  var project: VercelProject
  
  @State private var productionDeployment: VercelDeployment?
  @State private var deployments: [VercelDeployment] = []
  @State private var pagination: Pagination?
  
  #if os(iOS)
  var notificationsEnabled: Bool {
    NotificationManager.deploymentNotificationIds.contains { $0 == project.id }
  }
  #endif
  
  var body: some View {
    Form {
      if let productionDeployment = productionDeployment {
        Section("Current Production Deployment") {
          NavigationLink(destination: DeploymentDetailView(deployment: productionDeployment)) {
            DeploymentListRowView(deployment: productionDeployment)
          }
        }
      }
      
      Section("Recent Deployments") {
        ForEach(deployments) { deployment in
          NavigationLink(destination: DeploymentDetailView(deployment: deployment)) {
            DeploymentListRowView(deployment: deployment)
          }
        }
        
        if deployments.isEmpty {
          LoadingListCell(title: "Loading Deployments")
        }
        
        if let pageId = pagination?.next {
          LoadingListCell(title: "Loading Deployments")
            .task {
              do {
                try await loadDeployments(pageId: pageId)
              } catch {
                print(error)
              }
            }
        }
      }
    }
    #if os(iOS)
    .toolbar {
      ToolbarItem {
        Button {
          NotificationManager.shared.toggleNotifications(!notificationsEnabled, for: project.id)
        } label: {
          Label("Toggle notifications \(notificationsEnabled ? "off" : "on")", systemImage: notificationsEnabled ? "bell" : "bell.slash")
        }
      }
    }
    #endif
    .navigationTitle(project.name)
    .dataTask {
      try? await initialLoad()
    }
  }
  
  func initialLoad() async throws {
    try await loadProductionDeployment()
    try await loadDeployments()
  }
  
  func loadProductionDeployment() async throws {
    var productionDeploymentsRequest = VercelAPI.request(for: .deployments(version: 6), with: session.accountId, queryItems: [
      URLQueryItem(name: "projectId", value: project.id),
      URLQueryItem(name: "target", value: VercelDeployment.Target.production.rawValue)
    ])
    try session.signRequest(&productionDeploymentsRequest)
    
    let (data, _) = try await URLSession.shared.data(for: productionDeploymentsRequest)
    let productionDeploymentsResponse = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data)
    
    withAnimation {
      productionDeployment = productionDeploymentsResponse.deployments.first
    }
  }
  
  func loadDeployments(pageId: Int? = nil) async throws {
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "projectId", value: project.id),
    ]
    
    if let pageId = pageId {
      queryItems.append(URLQueryItem(name: "from", value: String(pageId - 1)))
    }
    
    var request = VercelAPI.request(for: .deployments(version: 6), with: session.accountId, queryItems: queryItems)
    try session.signRequest(&request)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let deploymentsResponse = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data)
    
    withAnimation {
      if deployments.isEmpty {
        deployments = deploymentsResponse.deployments
      } else {
        deployments += deploymentsResponse.deployments
        deployments.removeDuplicates()
      }
      
      pagination = deploymentsResponse.pagination
    }
  }
}
