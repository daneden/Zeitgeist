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
	@AppStorage(Preferences.authenticatedAccounts) private var accounts

	@State private var signInModel = SignInViewModel()
	@State private var presentSettingsView = false
	@State private var selectedAccount: VercelAccount?
	@State private var session: VercelSession?

	@State private var selectedProject: VercelProject?
	@State private var selectedDeployment: VercelDeployment?

	var body: some View {
		NavigationSplitView {
			Group {
				if let session {
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
			.backportSafeAreaBar {
					Menu {
						Picker(selection: $selectedAccount) {
							ForEach(accounts, id: \.self) { account in
								AccountListRowView(account: account)
							}
						} label: {
							Text("Accounts")
						}

						#if os(iOS)
						Button {
							presentSettingsView = true
						} label: {
							Label("Settings", systemImage: "gearshape")
								.backportCircleSymbolVariant()
						}
						#endif
					} label: {
						if let selectedAccount {
							AccountListRowView(account: selectedAccount)
						}
					}
			}
			#if os(iOS)
			.sheet(isPresented: $presentSettingsView) {
				NavigationView {
					SettingsView()
						.navigationBarTitleDisplayMode(.inline)
				}
			}
			#endif
			.navigationTitle(Text(verbatim: "Zeitgeist"))
		} content: {
			if let selectedProject, session != nil {
				ProjectDetailView(projectId: selectedProject.id, project: selectedProject, selectedDeployment: $selectedDeployment)
			} else {
				PlaceholderView(forRole: .ProjectDetail)
			}
		} detail: {
			NavigationStack {
				if let selectedDeployment, session != nil {
					DeploymentDetailView(deploymentId: selectedDeployment.id, deployment: selectedDeployment)
				} else {
					PlaceholderView(forRole: .DeploymentDetail)
				}
			}
		}
		.onAppear {
			selectedAccount = accounts.first
		}
		.task(id: accounts.first) {
			selectedAccount = accounts.first
		}
		.onChange(of: selectedAccount) { _, newAccount in
			updateSession(for: newAccount)
		}
		.onReceive(NotificationCenter.default.publisher(for: .VercelAccountAddedNotification)) { _ in
			selectedAccount = accounts.last
		}
		.onReceive(NotificationCenter.default.publisher(for: .VercelAccountWillBeRemovedNotification), perform: { output in
			guard let index = output.object as? Int else {
				return
			}

			let previousAccountIndex = accounts.index(before: index)
			let nextAccountIndex = accounts.index(after: index)

			if accounts.indices.contains(previousAccountIndex) {
				selectedAccount = accounts[previousAccountIndex]
			} else if accounts.indices.contains(nextAccountIndex) {
				selectedAccount = accounts[nextAccountIndex]
			} else if accounts.indices.contains(index) {
				selectedAccount = accounts[index]
			} else {
				selectedAccount = nil
			}
		})
		.environment(\.session, session)
	}

	private func updateSession(for account: VercelAccount?) {
		guard let account else {
			session = nil
			return
		}

		// Try to create a new session (validates token exists)
		session = VercelSession(account: account)
	}

	func deleteAccount(at indices: IndexSet) {
		for index in indices {
			VercelSession.deleteAccount(id: accounts[index].id)
		}
	}
}

struct AuthenticatedContentView_Previews: PreviewProvider {
	static var previews: some View {
		AuthenticatedContentView()
	}
}
