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
  @Environment(\.presentationMode) var presentationMode
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
          
          ForEach(DeploymentState.typicalCases, id: \.self) { state in
            DeploymentStateIndicator(state: state)
              .tag(StateFilter.filteredByState(state: state))
          }
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
    .toolbar {
      Button(action: { presentationMode.wrappedValue.dismiss() }) {
        Text("Close")
      }.keyboardShortcut(.cancelAction)
    }
    .navigationTitle("Filter Deployments")
    .makeContainer()
  }
}
