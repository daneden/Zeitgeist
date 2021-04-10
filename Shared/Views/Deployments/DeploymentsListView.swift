//
//  DeploymentsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

#if os(macOS)
typealias ZGDeploymentsListStyle = SidebarListStyle
let filterToolbarButtonPosition: ToolbarItemPlacement = .automatic
let filterStatusAlignment: HorizontalAlignment = .trailing
#else
typealias ZGDeploymentsListStyle = PlainListStyle
let filterToolbarButtonPosition: ToolbarItemPlacement = .bottomBar
let filterStatusAlignment: HorizontalAlignment = .center
#endif

struct DeploymentsListView: View {
  @Environment(\.session) var session
  @Environment(\.deeplink) var deeplink
  @State var selectedDeploymentID: String?
  
  @State var projectFilter: ProjectNameFilter = .allProjects
  @State var stateFilter: StateFilter = .allStates
  @State var productionFilter = false
  @State var filterVisible = false
  
  var body: some View {
    let deployments = session?.current?.deployments ?? []
    let projects = session?.current?.projects ?? []

    let filteredDeployments = filterDeployments(deployments)
    
    return Group {
      if filteredDeployments.isEmpty {
        if session?.current?.fetchState == .loading {
          ProgressView("Loading deployments...")
        } else {
          VStack(spacing: 0) {
            Spacer()
            Text("emptyState")
              .foregroundColor(.secondary)
            Spacer()
          }
        }
      } else {
        List(filterDeployments(deployments), id: \.self.id) { deployment in
          NavigationLink(
            destination: DeploymentDetailView(teamID: session?.current?.account.id ?? "", deploymentID: deployment.id),
            tag: deployment.id,
            selection: $selectedDeploymentID
          ) {
            DeploymentsListRowView(deployment: deployment)
          }
        }
        .listStyle(ZGDeploymentsListStyle())
      }
    }
    .onAppear {
      session?.current?.loadDeployments()
      
      if self.selectedDeploymentID == nil {
        self.selectedDeploymentID = filteredDeployments.first?.id
      }
    }
    .onChange(of: deeplink) { deeplink in
      DispatchQueue.main.async {
        if case .deployment(let teamId, let deploymentId) = deeplink {
          self.selectedDeploymentID = deploymentId
          self.session?.selectedAccount = teamId
        }
      }
    }
    .navigationTitle(Text("Deployments"))
    .toolbar {
      ToolbarItem(placement: .status) {
        VStack(alignment: filterStatusAlignment) {
          if filtersApplied() {
            Text("\(filterDeployments(deployments).count) of \(deployments.count) deployments shown")
            if !IS_MACOS {
              Button(action: { self.filterVisible.toggle() }, label: {
                Text("Filters applied")
                  .font(.caption)
                  .foregroundColor(.accentColor)
              })
            }
          } else {
            Text("\(deployments.count) deployments shown")
          }
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }
      
      ToolbarItem(placement: filterToolbarButtonPosition) {
        Button(action: { self.filterVisible.toggle() }, label: {
          Label(
            "Filter by project",
            systemImage: filtersApplied()
              ? "line.horizontal.3.decrease.circle.fill"
              : "line.horizontal.3.decrease.circle"
          ).labelStyle(IconOnlyLabelStyle())
        })
      }
    }
    .sheet(isPresented: self.$filterVisible) {
      DeploymentsFilterView(
        projects: projects,
        projectFilter: self.$projectFilter,
        stateFilter: self.$stateFilter,
        productionFilter: self.$productionFilter
      )
    }
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
  
  func filtersApplied() -> Bool {
    return
      self.projectFilter != .allProjects ||
      self.productionFilter ||
      self.stateFilter != .allStates
  }
}

struct DeploymentsListView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentsListView()
  }
}
