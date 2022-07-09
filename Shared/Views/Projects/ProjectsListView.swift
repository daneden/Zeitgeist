//
//  ProjectsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI

struct ProjectsListView: View {
  @State var projects: [VercelProject] = []
  var body: some View {
    List(projects) { project in
      NavigationLink(destination: ProjectDetailView(project: project)) {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text(project.name)
              .font(.headline)
            Spacer()
            Text(project.updated ?? project.created, style: .relative)
              .foregroundStyle(.secondary)
          }
          
          if let repoSlug = project.link?.repoSlug,
             let provider = project.link?.type {
            HStack {
              GitProviderImage(provider: provider)
              Text(repoSlug)
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
          }
        }
        .padding(.vertical, 4)
      }
    }
    .task {
      try? await loadProjects()
    }
    .refreshable {
      try? await loadProjects()
    }
  }
  
  func loadProjects() async throws {
    let request = try VercelAPI.request(for: .projects, with: Session.shared.accountId!)
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(VercelProject.APIResponse.self, from: data)
    withAnimation {
      self.projects = decoded.projects
    }
  }
}
