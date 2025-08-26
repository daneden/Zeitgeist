//
//  ProjectDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI

struct ProjectDetailView: View {
	@EnvironmentObject var session: VercelSession
	var projectId: VercelProject.ID
	@State var project: VercelProject?

	@State private var filter = DeploymentFilter()
	@State private var deployments: [VercelDeployment] = []
	@State private var pagination: Pagination?
	@State private var projectNotificationsVisible = false

	@AppStorage(Preferences.deploymentNotificationIds)
	private var deploymentNotificationIds

	@AppStorage(Preferences.deploymentErrorNotificationIds)
	private var deploymentErrorNotificationIds

	@AppStorage(Preferences.deploymentReadyNotificationIds)
	private var deploymentReadyNotificationIds

	var notificationsEnabled: Bool {
		(deploymentNotificationIds + deploymentReadyNotificationIds + deploymentErrorNotificationIds)
			.contains { $0 == projectId }
	}
	
	var navBarTitle: Text {
		guard let name = project?.name else {
			return Text("Project Details")
		}
		
		return Text(name)
	}

	var body: some View {
		Form {
			if let project {
				Section("Details") {
					LabelView(Text("Name")) {
						Text(project.name)
					}
					
					if let gitLink = project.link,
						 let url = gitLink.repoUrl {
						let slug = gitLink.repoSlug
						let provider = gitLink.type
						
						LabelView(Text("Git Repository")) {
							Link(destination: url) {
								Label(slug, image: provider.rawValue)
							}
						}
						
						LabelView(Text("Production Branch")) {
							Text(gitLink.productionBranch)
						}
						
						NavigationLink(destination: ProjectEnvironmentVariablesView(projectId: project.id).environmentObject(session)) {
							Text("Environment Variables")
						}
					}
				}
				
				if let productionDeployment = project.targets?.production {
					Section("Current Production Deployment") {
						NavigationLink {
							DeploymentDetailView(deploymentId: productionDeployment.id, deployment: productionDeployment)
								.id(productionDeployment.id)
								.environmentObject(session)
						} label: {
							DeploymentListRowView(deployment: productionDeployment)
								.id(productionDeployment.id)
						}
					}
				}
				
				Section("Recent Deployments") {
					if filter.filtersApplied {
						Button {
							filter = .init()
						} label: {
							Label("Clear filters", systemImage: "xmark.circle")
						}
					}
					ForEach(deployments) { deployment in
						NavigationLink {
							DeploymentDetailView(deploymentId: deployment.id, deployment: deployment)
								.id(deployment.id)
								.environmentObject(session)
						} label: {
							DeploymentListRowView(deployment: deployment)
								.id(deployment.id)
						}
					}
					
					if deployments.isEmpty {
						LoadingListCell(title: "Loading deployments")
					}
					
					if let pageId = pagination?.next {
						LoadingListCell(title: "Loading deployments")
							.task {
								do {
									try await loadDeployments(pageId: pageId)
								} catch {
									print(error)
								}
							}
					}
				}
			} else {
				ProgressView()
			}
		}
		.toolbar {
			ToolbarItem {
				Button {
					projectNotificationsVisible = true
				} label: {
					Label("Notification settings", systemImage: notificationsEnabled ? "bell.badge" : "bell.slash")
				}
			}
			
			if #available(iOS 26, macOS 26, *) {
				ToolbarSpacer()
			}
			
			ToolbarItem {
				Menu {
					DeploymentFilterView(filter: $filter)
				} label: {
					Label("Filter deployments", systemImage: "line.3.horizontal.decrease")
						.backportCircleSymbolVariant()
						.symbolVariant(filter.filtersApplied ? .fill : .none)
				}
			}
		}
		.navigationTitle(navBarTitle)
		.onChange(of: filter) { _ in
			Task {
				try? await loadDeployments()
			}
		}
		.dataTask {
			do {
				try await initialLoad()
			} catch {
				print(error)
			}
		}
		.sheet(isPresented: $projectNotificationsVisible) {
			notificationsSheet
		}
	}
	
	@ViewBuilder
	var notificationsSheet: some View {
		if let project {
			Group {
				#if os(iOS)
				NavigationView {
					ProjectNotificationsView(project: project)
				}
				#else
				ProjectNotificationsView(project: project)
				#endif
			}
			.presentationDetents([.medium])
		}
	}

	func initialLoad() async throws {
		try await loadDeployments()
		try await loadProject()
	}
	
	func loadProject() async throws {
		var request = VercelAPI.request(for: .projects(projectId), with: session.account.id)
		try session.signRequest(&request)
		
		let (data, _) = try await URLSession.shared.data(for: request)
		let projectResponse = try JSONDecoder().decode(VercelProject.self, from: data)
		
		withAnimation {
			self.project = projectResponse
		}
	}

	func loadDeployments(pageId: Int? = nil) async throws {
		var queryItems: [URLQueryItem] = [
			URLQueryItem(name: "projectId", value: projectId),
		] + filter.urlQueryItems

		if let pageId = pageId {
			queryItems.append(URLQueryItem(name: "from", value: String(pageId - 1)))
		}

		var request = VercelAPI.request(for: .deployments(),
																		with: session.account.id,
																		queryItems: queryItems)
		try session.signRequest(&request)

		if pageId == nil,
		   let cachedResponse = URLCache.shared.cachedResponse(for: request),
		   let decodedFromCache = try? JSONDecoder().decode(VercelDeployment.APIResponse.self, from: cachedResponse.data)
		{
			deployments = decodedFromCache.deployments
		}

		let (data, _) = try await URLSession.shared.data(for: request)
		let deploymentsResponse = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data)

		withAnimation {
			if deployments.isEmpty || pageId == nil {
				deployments = deploymentsResponse.deployments
			} else {
				deployments += deploymentsResponse.deployments
			}

			pagination = deploymentsResponse.pagination
		}
	}
}
