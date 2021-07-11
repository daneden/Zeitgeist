//
//  DeploymentListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct DeploymentListView: View {
  @EnvironmentObject var session: Session
  
  @State var projectFilter: ProjectNameFilter = .allProjects
  @State var stateFilter: StateFilter = .allStates
  @State var productionFilter = false
  @State var filterVisible = false
  
  @State var activeDeploymentID: String?
  
  var filtersApplied: Bool {
    projectFilter != .allProjects || stateFilter != .allStates || productionFilter == true
  }
  
  var accountId: String
  var deploymentsSource: DeploymentsViewModel
  
  init(accountId: String) {
    self.accountId = accountId
    self.deploymentsSource = DeploymentsViewModel(accountId: accountId)
  }
  
  var body: some View {
    AsyncContentView(source: deploymentsSource) { deployments in
      if let filteredDeployments = filterDeployments(deployments) {
        
        if filteredDeployments.isEmpty {
          VStack(spacing: 8) {
            Spacer()
            
            PlaceholderView(forRole: .NoDeployments)
            
            if filtersApplied {
              Button(action: clearFilters) {
                Label("Clear Filters", systemImage: "xmark.circle")
              }
            }
            
            Spacer()
          }
        }
        
        List {
          ForEach(filteredDeployments, id: \.id) { deployment in
            NavigationLink(
              destination: DeploymentDetailView(accountId: accountId, deployment: deployment),
              tag: deployment.id,
              selection: $activeDeploymentID
            ) {
              DeploymentListRowView(deployment: deployment)
            }
          }
        }
        .sheet(isPresented: self.$filterVisible) {
          DeploymentFilterView(
            deployments: deployments,
            projectFilter: self.$projectFilter,
            stateFilter: self.$stateFilter,
            productionFilter: self.$productionFilter
          )
        }
      }
    }
    .toolbar {
      Button(action: { self.filterVisible.toggle() }) {
        Label(
          "Filter Deployments",
          systemImage: !filtersApplied
            ? "line.horizontal.3.decrease.circle"
            : "line.horizontal.3.decrease.circle.fill"
        )
      }
      
      Button(action: { deploymentsSource.load() }) {
        Label("Reload", systemImage: "arrow.clockwise")
      }
    }
    .navigationTitle("Deployments")
    .onOpenURL(perform: { url in
      switch url.detailPage {
      case .deployment(_, let deploymentId):
        self.activeDeploymentID = deploymentId
        return
      default:
        return
      }
    })
  }
  
  func clearFilters() {
    projectFilter = .allProjects
    stateFilter = .allStates
    productionFilter = false
  }
  
  func filterDeployments(_ deployments: [Deployment]) -> [Deployment] {
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
}
