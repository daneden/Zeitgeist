//
//  ProjectDetailView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import SwiftUI
import Suite

struct ProjectDetailView: View {
	@Environment(\.session) private var session
	var projectId: VercelProject.ID
	@State var project: VercelProject?
	@Binding var selectedDeployment: VercelDeployment?

	@State private var filter = DeploymentFilter()
	@State private var deployments: [VercelDeployment] = []
	@State private var pagination: Pagination?
	@State private var projectNotificationsVisible = false
	@State private var editEnvironmentVariables = false

	@State private var currentProductionDeployment: VercelDeployment?

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
			return Text("Project details")
		}

		return Text(name)
	}

	var body: some View {
		List(selection: $selectedDeployment) {
			if let project {
				Section("Details") {
					LabelView(Text("Name")) {
						Text(project.name)
					}

					if let gitLink = project.link,
						 let url = gitLink.repoUrl {
						let slug = gitLink.repoSlug
						let provider = gitLink.type

						LabelView(Text("Git repository")) {
							Link(destination: url) {
								Label(slug, image: provider.rawValue)
							}
						}

						LabelView(Text("Production branch")) {
							Text(gitLink.productionBranch)
						}
						
						LabeledContent {
							Button("Edit...") {
								editEnvironmentVariables = true
							}
						} label: {
							if let env = project.env {
								Text("\(env.count) environment variables")
							} else {
								Text("Environment variables")
							}
						}
						.sheet(isPresented: $editEnvironmentVariables) {
							ProjectEnvironmentVariablesView(envVars: project.env ?? [], projectId: project.id)
							#if os(macOS)
								.modify {
									if #available(macOS 15, *) {
										$0.presentationSizing(.page)
									} else {
										$0
									}
								}
							#endif
						}
					}
				}

				if let currentProductionDeployment {
					Section("Current Production Deployment") {
						NavigationLink(value: currentProductionDeployment) {
							DeploymentListRowView(deployment: currentProductionDeployment, isCurrentProduction: true)
								.id(currentProductionDeployment.id)
						}
						.tag(currentProductionDeployment)
					}
				}

				Section("Recent deployments") {
					if filter.filtersApplied {
						Button {
							filter = .init()
						} label: {
							Label("Clear filters", systemImage: "xmark.circle")
						}
					}

					ForEach(deployments) { deployment in
						NavigationLink(value: deployment) {
							DeploymentListRowView(
								deployment: deployment,
								isCurrentProduction: deployment.id == project.targets?.production?.id
							)
								.id(deployment.id)
						}
						.tag(deployment)
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
		#if os(iOS)
		.listStyle(.insetGrouped)
		#elseif os(macOS)
		.listStyle(.inset)
		#endif
		.toolbar {
			ToolbarItem {
				Button {
					projectNotificationsVisible = true
				} label: {
					Label("Notification settings", systemImage: notificationsEnabled ? "bell.badge" : "bell.slash")
				}
			}

			if #available(iOS 26, macOS 26, *) {
				ToolbarSpacer(.fixed)
			}

			ToolbarItem {
				Menu {
					DeploymentFilterView(filter: $filter)
				} label: {
					Label("Filter deployments", systemImage: "line.3.horizontal.decrease")
						.backportCircleSymbolVariant()
						.symbolVariant(filter.filtersApplied ? .circle.fill : .none)
				}
			}
		}
		.navigationTitle(navBarTitle)
		.focusedSceneValue(\.focusedProject, project)
		.onChange(of: filter) { _, _ in
			Task {
				try? await loadDeployments()
			}
		}
		.zeitgeistDataTask {
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
				NavigationStack {
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
		async let project: Void = loadProject()
		async let deployments: Void = loadDeployments()

		try await project
		try await deployments
	}

	func loadProject() async throws {
		guard let session else { return }
		
		/// Try to decode a current production deployment as soon as possible
		if let currentProductionDeploymentId = project?.targets?.production?.id {
			let request = VercelAPI.request(for: .deployments(version: 13, deploymentID: currentProductionDeploymentId), with: session.account.id)
			if let cachedResponse = URLCache.shared.cachedResponse(for: request)?.data,
				 let decodedFromCache = try? JSONDecoder().decode(VercelDeployment.self, from: cachedResponse) {
				self.currentProductionDeployment = decodedFromCache
			}
		}
		
		var request = VercelAPI.request(for: .projects(projectId), with: session.account.id)
		try session.signRequest(&request)

		let (data, _) = try await URLSession.shared.data(for: request)
		let projectResponse = try JSONDecoder().decode(VercelProject.self, from: data)

		withAnimation {
			self.project = projectResponse
		}

		if let currentProductionDeploymentID = projectResponse.targets?.production?.id {
			var currentProductionDeploymentRequest = VercelAPI.request(for: .deployments(version: 13, deploymentID: currentProductionDeploymentID), with: session.account.id)
			try session.signRequest(&currentProductionDeploymentRequest)

			let (data, _) = try await URLSession.shared.data(for: currentProductionDeploymentRequest)
			try withAnimation {
				self.currentProductionDeployment = try JSONDecoder().decode(VercelDeployment.self, from: data)
			}
		}
	}

	func loadDeployments(pageId: Int? = nil) async throws {
		guard let session else { return }
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
