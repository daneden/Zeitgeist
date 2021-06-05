//
//  DeploymentFilterView.swift
//  Verdant
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

enum StateFilter: Hashable {
  case allStates
  case filteredByState(state: DeploymentState)
}

enum TargetFilter: Hashable {
  case allTargets
  case filteredByTarget(target: DeploymentTarget)
}

enum ProjectNameFilter: Hashable {
  case allProjects
  case filteredByProjectName(name: String)
}

struct DeploymentFilterView: View {
  var deployments: [Deployment]
  
  var projects: [String] {
    Array(Set(deployments.map { $0.project })).sorted()
  }
  
  @Binding var projectFilter: ProjectNameFilter
  @Binding var stateFilter: StateFilter
  @Binding var productionFilter: Bool
  
  var filtersApplied: Bool {
    return
      self.projectFilter != .allProjects ||
      self.productionFilter ||
      self.stateFilter != .allStates
  }
  
  var body: some View {
    NavigationView {
      Form {
        Section(header: Text("Filter deployments by:")) {
          Picker("Project", selection: $projectFilter) {
            Text("All projects").tag(ProjectNameFilter.allProjects)
            
            ForEach(projects, id: \.self) { project in
              Text(project).tag(ProjectNameFilter.filteredByProjectName(name: project))
            }
          }
          
          Picker("Status", selection: $stateFilter) {
            Text("All statuses").tag(StateFilter.allStates)
            
            Label("Deployed", systemImage: "checkmark.circle.fill")
              .tag(StateFilter.filteredByState(state: .ready))
            
            Label("Building", systemImage: "timer")
              .tag(StateFilter.filteredByState(state: .building))
            Label("Build error", systemImage: "exclamationmark.circle.fill")
              .tag(StateFilter.filteredByState(state: .error))
            Label("Cancelled", systemImage: "x.circle.fill")
              .tag(StateFilter.filteredByState(state: .cancelled))
            Label("Queued", systemImage: "hourglass")
              .tag(StateFilter.filteredByState(state: .queued))
          }.accentColor(.secondary)
          
          Toggle(isOn: self.$productionFilter) {
            Label("Production Deployments Only", systemImage: "bolt.fill")
              .accentColor(.systemOrange)
          }.toggleStyle(SwitchToggleStyle(tint: .accentColor))
        }
        
        Section {
          Button(action: {
            withAnimation {
              self.projectFilter = .allProjects
              self.productionFilter = false
              self.stateFilter = .allStates
            }
          }, label: {
            Text("Clear filters")
          })
          .disabled(!filtersApplied)
        }
      }
      .navigationTitle("Filter Deployments")
    }
  }
}
