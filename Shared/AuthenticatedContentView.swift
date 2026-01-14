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

	@State private var signInModel = SignInViewModel()
	@State private var selectedProject: VercelProject?
	@State private var selectedDeployment: VercelDeployment?

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
					ContentUnavailableView("No account selected", image: "person.fill.questionmark")
				}
			}
			.withAccountSwitcher()
			.navigationTitle(Text(verbatim: "Zeitgeist"))
		} content: {
			if let selectedProject, session != nil {
				ProjectDetailView(projectId: selectedProject.id, project: selectedProject, selectedDeployment: $selectedDeployment)
			} else {
				PlaceholderView(forRole: .ProjectDetail)
			}
		} detail: {
			NavigationStack {
				Group {
					if let selectedDeployment, session != nil {
						DeploymentDetailView(deploymentId: selectedDeployment.id, deployment: selectedDeployment)
					} else {
						PlaceholderView(forRole: .DeploymentDetail)
					}
				}
				.navigationDestination(for: DetailDestinationValue.self) { destination in
					switch destination {
					case .deploymentLogs(let deployment):
						DeploymentLogView(deployment: deployment)
							.environment(\.session, session)
					}
				}
			}
		}
		.onChange(of: selectedProject) { _, newProject in
			selectedProjectId = newProject?.id
		}
		.environment(\.session, session)
	}

	func deleteAccount(at indices: IndexSet) {
		for index in indices {
			accountManager.deleteAccount(id: accountManager.accounts[index].id)
		}
	}
}

struct AuthenticatedContentView_Previews: PreviewProvider {
	static var previews: some View {
		AuthenticatedContentView()
	}
}
