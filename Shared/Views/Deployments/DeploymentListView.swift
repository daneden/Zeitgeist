//
//  DeploymentListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI
import Combine

struct DeploymentListView: View {
  @EnvironmentObject var session: Session
  
  @State var projectFilter: ProjectNameFilter = .allProjects
  @State var stateFilter: StateFilter = .allStates
  @State var productionFilter = false
  @State var filterVisible = false
  
  @State private var deployments: [Deployment] = []
  
  private var filteredDeployments: [Deployment] {
    return deployments.filter { deployment -> Bool in
      switch self.projectFilter {
      case .allProjects:
        return true
      case .filteredByProjectName(let name):
        return name == deployment.project
      }
    }
    .filter { deployment -> Bool in
      switch self.stateFilter {
      case .allStates:
        return true
      case .filteredByState(let state):
        return state == deployment.state
      }
    }
    .filter { deployment -> Bool in
      return productionFilter ? deployment.target == .production : true
    }
  }
  
  @SceneStorage("activeDeploymentID") var activeDeploymentID: Deployment.ID?
  
  var filtersApplied: Bool {
    projectFilter != .allProjects || stateFilter != .allStates || productionFilter == true
  }
  
  var accountId: String
  @StateObject var deploymentsSource: DeploymentsViewModel
  
  var body: some View {
    Group {
      if filteredDeployments.isEmpty {
        VStack(spacing: 8) {
          Spacer()

          PlaceholderView(forRole: .NoDeployments)

          if filtersApplied {
            Button(action: clearFilters) {
              Label("Clear Filters", systemImage: "xmark.circle")
            }.symbolRenderingMode(.monochrome)
          }

          Spacer()
        }
      } else {
        List(filteredDeployments) { deployment in
          NavigationLink(
            destination: DeploymentDetailView(accountId: accountId, deployment: deployment)
              .environmentObject(deploymentsSource)
          ) {
            DeploymentListRowView(deployment: deployment)
          }
        }
      }
    }
    .toolbar {
      Button(action: { self.filterVisible.toggle() }) {
        Label("Filter Deployments", systemImage: "line.horizontal.3.decrease.circle")
      }
      .keyboardShortcut("l", modifiers: .command)
      .symbolVariant(filtersApplied ? .fill : .none)
    }
    .sheet(isPresented: self.$filterVisible) {
      #if os(iOS)
      NavigationView {
        DeploymentFilterView(
          deployments: deployments,
          projectFilter: self.$projectFilter,
          stateFilter: self.$stateFilter,
          productionFilter: self.$productionFilter
        )
      }
      #else
      DeploymentFilterView(
        deployments: deployments,
        projectFilter: self.$projectFilter,
        stateFilter: self.$stateFilter,
        productionFilter: self.$productionFilter
      )
      #endif
    }
    .task {
      try? await loadDeployments()
    }
    .refreshable {
      try? await loadDeployments()
    }
  }
  
  func loadDeployments() async throws {
    let request = try VercelAPI.request(for: .deployments(), with: Session.shared.accountId!)
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(Deployment.APIResponse.self, from: data)
    withAnimation {
      self.deployments = decoded.deployments
    }
  }
  
  func clearFilters() {
    projectFilter = .allProjects
    stateFilter = .allStates
    productionFilter = false
  }
}
