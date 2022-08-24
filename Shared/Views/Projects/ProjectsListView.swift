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
	
	@State private var errorMessage: String?
	
	var body: some View {
		ZStack {
			List {
				ForEach(projects) { project in
					NavigationLink {
						ProjectDetailView(project: project)
							.environmentObject(session)
					} label: {
						ProjectsListRowView(project: project)
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
			.dataTask { do { try await loadProjects() } catch {
				print(error)
				errorMessage = error.localizedDescription
			} }
			
			if projects.isEmpty {
				PlaceholderView(forRole: .NoProjects)
				
				VStack {
					if session.account == nil { Text("Account is nil") }
					if session.authenticationToken == nil { Text ("Token is nil") }
					if let errorMessage = errorMessage {
						Text(errorMessage)
					}
				}.font(.subheadline.monospaced())
			}
		}
		.navigationTitle("Projects")
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
			 let decodedFromCache = try? JSONDecoder().decode(VercelProject.APIResponse.self, from: cachedResponse.data)
		{
			projects = decodedFromCache.projects
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

struct ProjectListPlaceholderView: View {
	var body: some View {
		NavigationView {
			List {
				ForEach(0..<10, id: \.self) { _ in
					ProjectsListRowView(project: .exampleData)
				}
			}
			.navigationTitle("Projects")
		}.redacted(reason: .placeholder)
	}
}
