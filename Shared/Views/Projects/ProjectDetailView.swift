//
//  ProjectDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI

struct DeploymentRow: View {
  var deployment: Deployment
  
  var body: some View {
    Link(destination: deployment.url) {
      HStack {
        Text(deployment.commit?.commitMessageSummary ?? "Manual Deployment")
        Spacer()
        Text(deployment.date, style: .relative)
          .foregroundStyle(.secondary)
      }
    }
  }
}

struct ProjectDetailView: View {
  var project: VercelProject
  @State private var productionDeployment: Deployment?
  @State private var previewDeployments: [Deployment] = []
  var body: some View {
    Form {
      if let productionDeployment = productionDeployment {
        Section("Production Deployment") {
          DeploymentRow(deployment: productionDeployment)
        }
      }
      
      Section("Preview Deployments") {
        ForEach(previewDeployments) { deployment in
          DeploymentRow(deployment: deployment)
        }
      }
    }
    .navigationTitle(project.name)
    .task {
      try? await loadDeployments()
    }
    .refreshable {
      try? await loadDeployments()
    }
  }
  
  func loadDeployments() async throws {
    guard let productionDeploymentsRequest = try? VercelAPI.request(for: .deployments(version: 6), with: Session.shared.accountId!, queryItems: [
      URLQueryItem(name: "projectId", value: project.id),
      URLQueryItem(name: "target", value: DeploymentTarget.production.rawValue)
    ]) else { return }
    
    let (data, _) = try await URLSession.shared.data(for: productionDeploymentsRequest)
    let productionDeploymentsResponse = try JSONDecoder().decode(Deployment.APIResponse.self, from: data)
    
    withAnimation {
      productionDeployment = productionDeploymentsResponse.deployments.first
    }
    
    guard let stagingDeploymentsRequest = try? VercelAPI.request(for: .deployments(version: 6), with: Session.shared.accountId!, queryItems: [
      URLQueryItem(name: "projectId", value: project.id),
    ]) else { return }
    
    let (previewData, _) = try await URLSession.shared.data(for: stagingDeploymentsRequest)
    let previewDeploymentsResponse = try JSONDecoder().decode(Deployment.APIResponse.self, from: previewData)
    
    withAnimation {
      previewDeployments = previewDeploymentsResponse.deployments.filter {
        $0.target != .production
      }
    }
  }
}
