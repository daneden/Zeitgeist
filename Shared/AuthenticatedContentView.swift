//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI
import Suite

struct AuthenticatedContentView: View {
	@Environment(\.webAuthenticationSession) private var webAuthenticationSession
	@Environment(AccountManager.self) var accountManager
	@Environment(DeepLinkHandler.self) var deepLinkHandler

	@State private var signInModel = SignInViewModel()
	@State private var selectedProject: VercelProject?
	@State private var selectedDeployment: VercelDeployment?
	@State private var isHandlingDeepLink = false
	@State private var focusedNavigationState = FocusedNavigationState()

	// Scene storage for navigation state persistence across app launches
	@SceneStorage("selectedProjectId") private var selectedProjectId: String?

	// Convenience accessors for cleaner code
	private var session: VercelSession? { accountManager.currentSession }
	private var selectedAccount: VercelAccount? { accountManager.selectedAccount }

	var body: some View {
		NavigationSplitView {
			Group {
				if session != nil {
					ProjectsListView(selectedProject: $selectedProject, selectedDeployment: $selectedDeployment)
				} else if selectedAccount != nil {
					// Account exists but session creation failed (missing token)
					ContentUnavailableView(
						"Authentication Required",
						systemImage: "key.slash",
						description: Text("Please sign in again to continue using this account.")
					)
				} else {
					ContentUnavailableView("No account selected", systemImage: "person.fill.questionmark")
				}
			}
			#if os(iOS)
			.withAccountSwitcher()
			#endif
			.navigationTitle(Text(verbatim: "Zeitgeist"))
			.backportNavigationSubtitle(session?.account.name ?? session?.account.username)
			.navigationSplitViewColumnWidth(min: 200, ideal: 240)
		} content: {
			Group {
				if let selectedProject, session != nil {
					ProjectDetailView(
						projectId: selectedProject.id,
						project: selectedProject,
						selectedProject: $selectedProject,
						selectedDeployment: $selectedDeployment
					)
						.id(selectedProject)
				} else {
					PlaceholderView(forRole: .ProjectDetail)
				}
			}
			.backportNavigationSubtitle(session?.account.name ?? session?.account.username)
			.navigationSplitViewColumnWidth(min: 200, ideal: 240)
		} detail: {
			Group {
				if let selectedDeployment, session != nil {
					DeploymentDetailView(
						deploymentId: selectedDeployment.id,
						deployment: selectedDeployment,
						selectedDeployment: $selectedDeployment
					)
						.id(selectedDeployment)
				} else {
					PlaceholderView(forRole: .DeploymentDetail)
				}
			}
			.id(selectedProject?.id)
		}
		.onChange(of: selectedProject) { _, newProject in
			let normalizedDeployment = normalizedDeployment(for: newProject, deployment: selectedDeployment)
			if selectedDeployment?.id != normalizedDeployment?.id {
				selectedDeployment = normalizedDeployment
			}
			selectedProjectId = newProject?.id
			syncFocusedNavigationState()
		}
		.onChange(of: selectedDeployment) { _, newDeployment in
			let normalizedDeployment = normalizedDeployment(for: selectedProject, deployment: newDeployment)
			if selectedDeployment?.id != normalizedDeployment?.id {
				selectedDeployment = normalizedDeployment
				return
			}
			syncFocusedNavigationState()
		}
		.onChange(of: deepLinkHandler.pendingDeepLink) { _, newValue in
			guard let deepLink = newValue, !isHandlingDeepLink else { return }
			Task {
				await handleDeepLink(deepLink)
			}
		}
		.focusedSceneValue(\.focusedProject, focusedNavigationState.project)
		.focusedSceneValue(\.focusedDeployment, focusedNavigationState.deployment)
		.environment(\.session, session)
		.environment(focusedNavigationState)
	}

	// MARK: - Deep Link Handling

	private func handleDeepLink(_ deepLink: DeepLinkHandler.DeepLink) async {
		isHandlingDeepLink = true
		defer {
			isHandlingDeepLink = false
			deepLinkHandler.pendingDeepLink = nil
		}

		switch deepLink {
		case .deployment(let accountId, let deploymentId, let projectId):
			await navigateToDeployment(accountId: accountId, deploymentId: deploymentId, projectId: projectId)
		}
	}

	private func navigateToDeployment(accountId: String, deploymentId: String, projectId: String?) async {
		// Switch account if needed
		if accountManager.selectedAccountId != accountId {
			guard accountManager.accounts.contains(where: { $0.id == accountId }) else {
				print("Deep link error: Account \(accountId) not found")
				return
			}
			accountManager.selectedAccountId = accountId
			// Wait a moment for session to update
			try? await Task.sleep(for: .milliseconds(100))
		}

		guard let session = accountManager.currentSession else {
			print("Deep link error: No active session for account \(accountId)")
			return
		}

		do {
				var deploymentRequest = VercelAPI.request(
					for: .deployments(version: 13, deploymentID: deploymentId),
					with: accountId
				)
				try session.signRequest(&deploymentRequest)
				let signedDeploymentRequest = deploymentRequest

				// If we have projectId, fetch both in parallel
				if let projectId {
					var projectRequest = VercelAPI.request(
						for: .projects(version: 9, projectId),
						with: accountId
					)
					try session.signRequest(&projectRequest)
					let signedProjectRequest = projectRequest

					// Try cache first for instant navigation
					if let (cachedDeployment, cachedProject) = getCachedData(
						deploymentRequest: signedDeploymentRequest,
						projectRequest: signedProjectRequest
					) {
						selectedProject = cachedProject
						selectedDeployment = cachedDeployment
					}

					// Fetch both in parallel
					async let deploymentTask = URLSession.shared.data(for: signedDeploymentRequest)
					async let projectTask = URLSession.shared.data(for: signedProjectRequest)

				let (deploymentResult, projectResult) = try await (deploymentTask, projectTask)

				let deployment = try JSONDecoder().decode(VercelDeployment.self, from: deploymentResult.0)
				let project = try JSONDecoder().decode(VercelProject.self, from: projectResult.0)

				selectedProject = project
				selectedDeployment = deployment
			} else {
				// No projectId - must fetch deployment first to get it
				// Try cache first
				if let cachedDeployment = getCachedDeployment(request: deploymentRequest) {
					if let projectId = cachedDeployment.projectId {
						var projectRequest = VercelAPI.request(
							for: .projects(version: 9, projectId),
							with: accountId
						)
						try session.signRequest(&projectRequest)

						if let cachedProject = getCachedProject(request: projectRequest) {
							selectedProject = cachedProject
							selectedDeployment = cachedDeployment
						}
					}
				}

				// Fetch deployment
				let (deploymentData, _) = try await URLSession.shared.data(for: deploymentRequest)
				let deployment = try JSONDecoder().decode(VercelDeployment.self, from: deploymentData)

				guard let projectId = deployment.projectId else {
					print("Deep link error: Deployment has no projectId")
					return
				}

				var projectRequest = VercelAPI.request(
					for: .projects(version: 9, projectId),
					with: accountId
				)
				try session.signRequest(&projectRequest)
				let (projectData, _) = try await URLSession.shared.data(for: projectRequest)
				let project = try JSONDecoder().decode(VercelProject.self, from: projectData)

				selectedProject = project
				selectedDeployment = deployment
			}
		} catch {
			print("Deep link error: \(error.localizedDescription)")
		}
	}

	// MARK: - Cache Helpers

	private func getCachedData(
		deploymentRequest: URLRequest,
		projectRequest: URLRequest
	) -> (VercelDeployment, VercelProject)? {
		guard let cachedDeployment = getCachedDeployment(request: deploymentRequest),
			  let cachedProject = getCachedProject(request: projectRequest) else {
			return nil
		}
		return (cachedDeployment, cachedProject)
	}

	private func getCachedDeployment(request: URLRequest) -> VercelDeployment? {
		guard let cachedResponse = URLCache.shared.cachedResponse(for: request) else {
			return nil
		}
		return try? JSONDecoder().decode(VercelDeployment.self, from: cachedResponse.data)
	}

	private func getCachedProject(request: URLRequest) -> VercelProject? {
		guard let cachedResponse = URLCache.shared.cachedResponse(for: request) else {
			return nil
		}
		return try? JSONDecoder().decode(VercelProject.self, from: cachedResponse.data)
	}

	private func normalizedDeployment(
		for project: VercelProject?,
		deployment: VercelDeployment?
	) -> VercelDeployment? {
		guard let deployment, deployment.projectId == project?.id else {
			return nil
		}

		return deployment
	}

	private func syncFocusedNavigationState() {
		let deployment = normalizedDeployment(for: selectedProject, deployment: selectedDeployment)
		focusedNavigationState.setProject(selectedProject)
		focusedNavigationState.setDeployment(deployment)
	}
}

struct AuthenticatedContentView_Previews: PreviewProvider {
	static var previews: some View {
		AuthenticatedContentView()
	}
}
