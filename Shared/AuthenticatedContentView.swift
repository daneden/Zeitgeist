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
	
	@State private var selectedProject: VercelProject?
	@State private var selectedDeployment: VercelDeployment?

	var body: some View {
		NavigationSplitView {
			Group {
				if let selectedAccount {
					ProjectsListView(selectedProject: $selectedProject, selectedDeployment: $selectedDeployment)
						.environmentObject(VercelSession(account: selectedAccount))
				} else {
					ContentUnavailableView("No account selected", image: "person.fill.questionmark")
				}
			}
			.toolbar {
				ToolbarItem(placement: .bottomBar) {
					Menu {
						Picker(selection: $selectedAccount) {
							ForEach(accounts, id: \.self) { account in
								AccountListRowView(account: account)
							}
						} label: {
							Text("Accounts")
						}
						.pickerStyle(.inline)
						
						#if os(iOS)
						Divider()
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
			if let selectedProject {
				ProjectDetailView(projectId: selectedProject.id, project: selectedProject, selectedDeployment: $selectedDeployment)
			} else {
				NavigationStack {
					PlaceholderView(forRole: .ProjectDetail)
				}
			}
		} detail: {
			if let selectedDeployment {
				DeploymentDetailView(deploymentId: selectedDeployment.id, deployment: selectedDeployment)
			} else {
				
			}
		}
		.onAppear {
			selectedAccount = accounts.first
		}
		.task(id: accounts.first) {
			selectedAccount = accounts.first
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
