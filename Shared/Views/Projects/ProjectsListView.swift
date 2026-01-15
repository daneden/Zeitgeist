//
//  ProjectsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI
import Suite

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
	@Environment(\.session) private var session

	@State private var projects: [VercelProject] = []
	@State private var pagination: Pagination?
	@State private var searchText = ""
	@State private var projectsError: SessionError?
	
	@State private var showAccountManagementView = false

	@Binding var selectedProject: VercelProject?
	@Binding var selectedDeployment: VercelDeployment?

	// Read stored project ID for restoration
	@SceneStorage("selectedProjectId") private var selectedProjectId: String?
	
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
			List(selection: $selectedProject) {
				#if os(macOS)
				if let selectedAccount = session?.account {
					Section {
						Button {
							showAccountManagementView = true
						} label: {
							HStack {
								AccountListRowView(account: selectedAccount)
									.frame(maxWidth: .infinity, alignment: .leading)
								
								Image(systemName: "chevron.up.chevron.down")
							}
							.contentShape(.capsule(style: .continuous))
						}
						.buttonStyle(.plain)
					}
					.sheet(isPresented: $showAccountManagementView) {
						AccountManagementView()
							.modify {
								if #available(macOS 15, *) {
									$0.presentationSizing(.form)
								} else {
									$0.frame(minHeight: 400)
								}
							}
					}
				}
				#endif
				
				ForEach(filteredProjects) { project in
					NavigationLink(value: project) {
						ProjectsListRowView(project: project)
							.id(project.id)
					}
				}
				
				if let pageId = pagination?.next {
					LoadingListCell(title: "Loading projects")
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
				ToolbarItem(placement: .secondaryAction) {
					Menu {
						Picker(selection: $projectSummaryDisplayOption) {
							ForEach(ProjectSummaryDisplayOption.allCases, id: \.self) { option in
								Text(option.description)
									.tag(option)
							}
						} label: {
							Label("Show deployment cause for...", systemImage: "rectangle.and.text.magnifyingglass")
						}
					} label: {
						Label("View options", systemImage: "eye")
							.backportCircleSymbolVariant()
					}
				}
				
				if #available(iOS 26, macOS 26, *) {
					ToolbarSpacer(.fixed)
				}
			}
			.zeitgeistDataTask {
				do {
					try await loadProjects()
					projectsError = nil

					// Restore selection from scene storage if available
					if selectedProject == nil,
					   let savedProjectId = selectedProjectId,
					   let restoredProject = projects.first(where: { $0.id == savedProjectId }) {
						selectedProject = restoredProject
					}
				} catch {
					print(error)
					if let error = error as? SessionError {
						self.projectsError = error
					}
				}
			}
			
			if projects.isEmpty && projectsError == nil {
				PlaceholderView(forRole: .NoProjects)
			}
			
			if projectsError != nil {
				PlaceholderView(forRole: .AuthError)
			}
		}
		.navigationTitle("Projects")
		.modify {
			if #available(iOS 26, macOS 11, *) {
				if let account = session?.account {
					$0.navigationSubtitle(account.name)
				} else {
					$0
				}
			} else {
				$0
			}
		}
		.focusedSceneValue(\.focusedAccount, session?.account)
		.modifier(OptionalPermissionRevocationDialogModifier(session: session))
	}
	
	func loadProjects(pageId: Int? = nil) async throws {
		guard let session else { return }
		if session.requestsDenied == true { return }

		var params: [URLQueryItem] = []

		if let pageId = pageId {
			params.append(URLQueryItem(name: "from", value: String(pageId - 1)))
		}

		var request = VercelAPI.request(for: .projects(version: 10), with: session.account.id, queryItems: params)
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
		NavigationStack {
			List {
				ForEach(0..<10, id: \.self) { _ in
					ProjectsListRowView(project: .exampleData)
				}
			}
			.navigationTitle(Text("Projects"))
		}.redacted(reason: .placeholder)
	}
}
