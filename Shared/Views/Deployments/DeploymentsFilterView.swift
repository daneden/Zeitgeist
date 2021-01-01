//
//  DeploymentsFilterView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
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

struct DeploymentsFilterView: View {
  @Environment(\.presentationMode) var presentationMode
  
  var projects: [Project]
  @Binding var projectFilter: ProjectNameFilter
  @Binding var stateFilter: StateFilter
  @Binding var productionFilter: Bool
  
  var body: some View {
    return NavigationView {
      Form {
        Section(header: Text("Filter deployments by:")) {
          Picker("Project", selection: $projectFilter) {
            Text("All projects").tag(ProjectNameFilter.allProjects)
            
            ForEach(projects, id: \.self) { project in
              Text(project.name).tag(ProjectNameFilter.filteredByProjectName(name: project.name))
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
          }
          
          Toggle(isOn: self.$productionFilter) {
            Label("Production deployents only", systemImage: "bolt.fill")
          }
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
          .disabled(!filtersApplied())
        }
      }
      .if(!IS_MACOS) {
        $0.toolbar {
          ToolbarItem {
            Button(action: { self.presentationMode.wrappedValue.dismiss() }, label: {
              Text("Done")
            })
          }
        }
      }
      .if(IS_MACOS) {
        $0.padding().fixedSize()
      }
      .navigationTitle(Text("Filters"))
    }
  }
  
  func filtersApplied() -> Bool {
    return
      self.projectFilter != .allProjects ||
      self.productionFilter ||
      self.stateFilter != .allStates
  }
}

struct DeploymentsFilterView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentsFilterView(
      projects: [],
      projectFilter: .constant(.allProjects),
      stateFilter: .constant(.allStates),
      productionFilter: .constant(false)
    )
  }
}
