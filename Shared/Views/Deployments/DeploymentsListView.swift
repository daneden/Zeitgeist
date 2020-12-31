//
//  DeploymentsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

enum ViewType: String, CaseIterable {
  case deployments = "Deployments", projects = "Projects"
}

#if os(macOS)
typealias ZGDeploymentsListStyle = SidebarListStyle
#else
typealias ZGDeploymentsListStyle = PlainListStyle
#endif

struct DeploymentsListView: View {
  @EnvironmentObject var vercelFetcher: VercelFetcher
  @State var team: VercelTeam = VercelTeam()
  @State var listOf: ViewType = .deployments
  
  @State var projectFilter: ProjectNameFilter = .allProjects
  @State var stateFilter: StateFilter = .allStates
  @State var productionFilter = false
  @State var filterVisible = false
  
  var body: some View {
    let deployments = vercelFetcher.deploymentsStore.store[team.id] ?? []
    let projects = vercelFetcher.projectsStore.store[team.id] ?? []
    
    return Group {
      if listOf == .deployments {
        if filteredDeployments(deployments).isEmpty {
          if vercelFetcher.fetchState == .loading {
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
          List(filteredDeployments(deployments), id: \.self) { deployment in
            NavigationLink(destination: DeploymentDetailView(deployment: deployment)) {
              DeploymentsListRowView(deployment: deployment)
                .id(deployment.id)
            }
          }
          .listStyle(ZGDeploymentsListStyle())
        }
      } else if listOf == .projects {
        if projects.isEmpty {
          VStack(spacing: 0) {
            Spacer()
            Text("emptyState")
              .foregroundColor(.secondary)
            Spacer()
          }
        } else {
          List(projects, id: \.self) { project in
            NavigationLink(destination: ProjectDetailView(project: project)) {
              VStack(alignment: .leading) {
                Text(project.name)
                Text("Updated \(project.updated, style: .relative) ago")
                  .font(.caption)
                  .foregroundColor(.secondary)
              }
            }
          }
          .listStyle(ZGDeploymentsListStyle())
        }
      }
    }
    .navigationTitle(Text(listOf.rawValue))
    .toolbar {
      ToolbarItem(placement: .status) {
        VStack {
          Text(team.name).fontWeight(.semibold)
            
          if filtersApplied() {
            Text("\(filteredDeployments(deployments).count) of \(deployments.count) deployments shown")
            Button(action: { self.filterVisible.toggle() }, label: {
              Text("Filters applied")
                .font(.caption)
                .foregroundColor(.accentColor)
            })
          } else {
            Text("\(deployments.count) deployments shown")
          }
        }
        .font(.caption)
        .foregroundColor(.secondary)
      }
      
      // TODO: Allow switching to Projects view
//      ToolbarItem(placement: .principal) {
//        Picker(selection: $listOf, label: Text("View:")) {
//          ForEach(ViewType.allCases, id: \.self) { item in
//            Text(item.rawValue)
//          }
//        }
//      }
      
      #if !os(macOS)
      ToolbarItem(placement: .bottomBar) {
        Button(action: { self.filterVisible.toggle() }, label: {
          Label(
            "Filter by project",
            systemImage: filtersApplied()
            ? "line.horizontal.3.decrease.circle.fill"
            : "line.horizontal.3.decrease.circle"
          ).labelStyle(IconOnlyLabelStyle())
        })
      }
      #endif
    }
    .sheet(isPresented: self.$filterVisible) {
      DeploymentsFilterView(
        projects: projects,
        projectFilter: self.$projectFilter,
        stateFilter: self.$stateFilter,
        productionFilter: self.$productionFilter
      )
    }
    .onAppear {
      vercelFetcher.tick()
    }
  }
  
  func filteredDeployments(_ deployments: [Deployment]) -> [Deployment] {
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
