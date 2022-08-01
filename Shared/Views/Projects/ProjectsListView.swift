//
//  ProjectsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI

struct LoadingListCell: View {
  var title: LocalizedStringKey = "Loading"
  var body: some View {
    HStack(spacing: 8) {
      ProgressView()
      Text(title)
    }
    .foregroundStyle(.secondary)
  }
}

struct ProjectsListView: View {
  @EnvironmentObject var session: VercelSession
  
  @State private var projects: [VercelProject] = []
  @State private var pagination: Pagination?
  
  var body: some View {
    List {
      ForEach(projects) { project in
        NavigationLink(destination: ProjectDetailView(project: project)) {
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
      
      if projects.isEmpty {
        LoadingListCell(title: "Loading Projects")
      }
      
      if let pageId = pagination?.next {
        LoadingListCell(title: "Loading Projects")
          .task {
            do {
              try await loadProjects(pageId: pageId)
            } catch {
              print(error)
            }
          }
      }
    }
    .dataTask { try? await loadProjects() }
  }
  
  func loadProjects(pageId: Int? = nil) async throws {
    var params: [URLQueryItem] = []
    
    if let pageId = pageId {
      params.append(URLQueryItem(name: "from", value: String(pageId - 1)))
    }
    
    var request = VercelAPI.request(for: .projects(), with: session.account?.id ?? .NullValue, queryItems: params)
    try session.signRequest(&request)
    
    if pageId == nil,
       let cachedResponse = URLCache.shared.cachedResponse(for: request),
       let decodedFromCache = try? JSONDecoder().decode(VercelProject.APIResponse.self, from: cachedResponse.data) {
      self.projects = decodedFromCache.projects
    }
    
    let (data, _) = try await URLSession.shared.data(for: request)
    let decoded = try JSONDecoder().decode(VercelProject.APIResponse.self, from: data)
    withAnimation {
      if pageId != nil {
        self.projects.append(contentsOf: decoded.projects)
      } else {
        self.projects = decoded.projects
      }
      self.pagination = decoded.pagination
    }
  }
}
