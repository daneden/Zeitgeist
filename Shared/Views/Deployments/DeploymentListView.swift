//
//  DeploymentListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI
import Combine

struct DeploymentListView: View {
  @EnvironmentObject var session: VercelSession
  
  @State var projectFilter: ProjectNameFilter = .allProjects
  @State var stateFilter: StateFilter = .allStates
  @State var productionFilter = false
  @State var filterVisible = false
  @State var pagination: Pagination?
  
  @State private var deployments: [VercelDeployment] = []
  
  private var filteredDeployments: [VercelDeployment] {
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
  
  var filtersApplied: Bool {
    projectFilter != .allProjects || stateFilter != .allStates || productionFilter == true
  }
  
  var accountId: String
  
  var body: some View {
    Group {
      if filteredDeployments.isEmpty && !deployments.isEmpty {
        VStack(spacing: 8) {
          Spacer()

          PlaceholderView(forRole: .NoDeployments)

          Button(action: clearFilters) {
            Label("Clear Filters", systemImage: "xmark.circle")
          }.symbolRenderingMode(.monochrome)

          Spacer()
        }
      } else {
        List {
          ForEach(filteredDeployments) { deployment in
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
  
  func loadDeployments(pageId: Int? = nil) async throws {
    var params: [URLQueryItem] = []
    
    if let pageId = pageId {
      params.append(URLQueryItem(name: "from", value: String(pageId - 1)))
    }
    
    var request = try VercelAPI.request(for: .deployments(), with: session.accountId, queryItems: params)
    try session.signRequest(&request)
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data)
    withAnimation {
      if pageId != nil {
        self.deployments.append(contentsOf: decoded.deployments)
      } else {
        self.deployments = decoded.deployments
      }
      
      self.pagination = decoded.pagination
    }
  }
  
  func clearFilters() {
    projectFilter = .allProjects
    stateFilter = .allStates
    productionFilter = false
  }
}
