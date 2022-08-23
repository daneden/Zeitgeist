//
//  ProjectDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI

struct ProjectDetailView: View {
	@EnvironmentObject var session: VercelSession
	@State var project: VercelProject

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
			.contains { $0 == project.id }
	}

	var body: some View {
		Form {
			Section("Details") {
				LabelView("Name") {
					Text(project.name)
				}

				if let gitLink = project.link,
				   let slug = gitLink.repoSlug,
				   let provider = gitLink.type,
				   let url = gitLink.repoUrl
				{
					LabelView("Git Repository") {
						Link(destination: url) {
							Label(slug, image: provider.rawValue)
						}
					}
				}
			}

			if let productionDeployment = project.targets?.production {
				Section("Current Production Deployment") {
					NavigationLink {
						DeploymentDetailView(deployment: productionDeployment)
							.environmentObject(session)
					} label: {
						DeploymentListRowView(deployment: productionDeployment)
					}
				}
			}

			Section("Recent Deployments") {
				#if os(macOS)
				Table(deployments) {
					TableColumn("Status") { deployment in
						DeploymentStateIndicator(state: deployment.state, style: .compact)
					}.width(16)
					TableColumn("Cause", value: \.deploymentCause.description)
					TableColumn("Date") { deployment in
						Text(deployment.created, style: .relative)
					}
				}
				#else
				ForEach(deployments) { deployment in
					NavigationLink {
						DeploymentDetailView(deployment: deployment)
							.environmentObject(session)
					} label: {
						DeploymentListRowView(deployment: deployment)
					}
				}

				if deployments.isEmpty {
					LoadingListCell(title: "Loading Deployments")
				}

				if let pageId = pagination?.next {
					LoadingListCell(title: "Loading Deployments")
						.task {
							do {
								try await loadDeployments(pageId: pageId)
							} catch {
								print(error)
							}
						}
				}
				#endif
			}
		}
		.toolbar {
			ToolbarItem {
				Button {
					projectNotificationsVisible = true
				} label: {
					Label("Notification settings)", systemImage: notificationsEnabled ? "bell.badge" : "bell.slash")
				}
			}
		}
		.navigationTitle(project.name)
		.dataTask {
			do {
				try await initialLoad()
			} catch {
				print(error)
			}
		}
		.sheet(isPresented: $projectNotificationsVisible) {
			#if os(iOS)
				NavigationView {
					ProjectNotificationsView(project: project)
				}
			#else
				ProjectNotificationsView(project: project)
			#endif
		}
	}

	func initialLoad() async throws {
		try await loadDeployments()
		try await loadProject()
	}
	
	func loadProject() async throws {
		var request = VercelAPI.request(for: .projects(project.id), with: session.account?.id ?? .NullValue)
		try session.signRequest(&request)
		
		let (data, _) = try await URLSession.shared.data(for: request)
		let projectResponse = try JSONDecoder().decode(VercelProject.self, from: data)
		
		withAnimation {
			self.project = projectResponse
		}
	}

	func loadDeployments(pageId: Int? = nil) async throws {
		var queryItems: [URLQueryItem] = [
			URLQueryItem(name: "projectId", value: project.id),
		]

		if let pageId = pageId {
			queryItems.append(URLQueryItem(name: "from", value: String(pageId - 1)))
		}

		var request = VercelAPI.request(for: .deployments(),
																		with: session.account?.id ?? .NullValue,
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
