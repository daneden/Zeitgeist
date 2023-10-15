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
			ProgressView().controlSize(.small)
			Text(title)
		}
		.foregroundStyle(.secondary)
	}
}

struct ProjectsListView: View {
	@AppStorage(Preferences.projectSummaryDisplayOption) var projectSummaryDisplayOption
	@EnvironmentObject var session: VercelSession
	
	@State private var projects: [VercelProject] = []
	@State private var pagination: Pagination?
	@State private var searchText = ""
	
	var filteredProjects: [VercelProject] {
		if searchText.isEmpty {
			return projects
		} else {
			return projects.filter { project in
				project.name.localizedCaseInsensitiveContains(searchText) || project.link?.repoSlug.localizedCaseInsensitiveContains(searchText) == true
			}
		}
	}
	
	var body: some View {
		ZStack {
			List {
				ForEach(filteredProjects) { project in
					NavigationLink {
						ProjectDetailView(projectId: project.id, project: project)
							.id(project.id)
							.environmentObject(session)
					} label: {
						ProjectsListRowView(project: project)
							.id(project.id)
					}
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
			.searchable(text: $searchText)
			.toolbar {
				Menu {
					Picker(selection: $projectSummaryDisplayOption) {
						ForEach(ProjectSummaryDisplayOption.allCases, id: \.self) { option in
							Text(option.description)
								.tag(option)
						}
					} label: {
						Label("Show deployment cause for...", systemImage: "info.circle")
					}
				} label: {
					Label("View Options", systemImage: "eye.circle")
				}
			}
			.dataTask { do { try await loadProjects() } catch { print(error) } }
			
			if projects.isEmpty {
				PlaceholderView(forRole: .NoProjects)
			}
		}
		.navigationTitle(Text("Projects"))
		.permissionRevocationDialog(session: session)
	}
	
	func loadProjects(pageId: Int? = nil) async throws {
		if session.requestsDenied == true { return }
		
		var params: [URLQueryItem] = []
		
		if let pageId = pageId {
			params.append(URLQueryItem(name: "from", value: String(pageId - 1)))
		}
		
		var request = VercelAPI.request(for: .projects(), with: session.account.id, queryItems: params)
		try session.signRequest(&request)
		
		if pageId == nil,
			 let cachedResponse = URLCache.shared.cachedResponse(for: request),
			 let decodedFromCache = try? JSONDecoder().decode(VercelProject.APIResponse.self, from: cachedResponse.data)
		{
			projects = decodedFromCache.projects
		}
		
		let (data, response) = try await URLSession.shared.data(for: request)
		session.validateResponse(response)
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

struct ProjectListPlaceholderView: View {
	var body: some View {
		NavigationView {
			List {
				ForEach(0..<10, id: \.self) { _ in
					ProjectsListRowView(project: .exampleData)
				}
			}
			.navigationTitle(Text("Projects"))
		}.redacted(reason: .placeholder)
	}
}
