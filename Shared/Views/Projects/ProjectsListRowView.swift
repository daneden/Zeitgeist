//
//  ProjectsListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 07/08/2022.
//

import SwiftUI

struct ProjectsListRowView: View {
  var project: VercelProject
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack(alignment: .firstTextBaseline) {
        Text(project.name)
          .font(.headline)
        Spacer()
        Text(project.updated ?? project.created, style: .relative)
          .foregroundStyle(.secondary)
          .font(.caption)
      }
      
      if let productionDeploymentCause = project.targets?.production?.deploymentCause {
        if let icon = productionDeploymentCause.icon {
          Text("\(Image(icon)) \(productionDeploymentCause.description)").lineLimit(2)
        } else {
          Text(productionDeploymentCause.description).lineLimit(2)
        }
      }
      
      if let repoSlug = project.link?.repoSlug,
         let provider = project.link?.type {
        Text("\(Image(provider.rawValue)) \(repoSlug)")
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
  }
}

struct ProjectsListRowView_Previews: PreviewProvider {
    static var previews: some View {
      ProjectsListRowView(project: .exampleData)
        .previewLayout(.sizeThatFits)
    }
}
