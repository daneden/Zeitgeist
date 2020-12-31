//
//  ProjectDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct ProjectDetailView: View {
  @State var project: Project
  
  var body: some View {
    Form {
      DeploymentDetailLabel("Last Updated") {
        Text("\(project.updated, style: .relative) ago")
      }
      
      DetailSection(title: Text("Latest Deployments")) {
        List {
//          ForEach(project.latestDeployments ?? [], id: \.self) { deployment in
//            NavigationLink(destination: DeploymentDetailView(deployment: deployment, projectName: project.name)) {
//              DeploymentsListRowView(deployment: deployment, projectName: project.name)
//            }
//          }
        }
      }
    }.navigationTitle(project.name)
  }
}

struct ProjectDetailView_Previews: PreviewProvider {
  static var previews: some View {
    ProjectDetailView(project: ExampleProject().project!)
  }
}
