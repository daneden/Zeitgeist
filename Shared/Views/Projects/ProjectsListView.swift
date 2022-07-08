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
        VStack(alignment: .leading) {
          Text(project.name)
          if let repoSlug = project.link?.repoSlug {
            Text(repoSlug).foregroundStyle(.secondary)
          }
        }
      }
    }
    .task {
      let request = try? VercelAPI.request(for: .projects, with: Session.shared.accountId!)
      guard let request = request else { return }
      let data = try? await URLSession.shared.data(for: request)
      
      do {
        guard let data = data?.0 else { return }
        let decoded = try JSONDecoder().decode(VercelProject.APIResponse.self, from: data)
        withAnimation {
          self.projects = decoded.projects
        }
      } catch {
        print(error)
      }
    }
  }
}
