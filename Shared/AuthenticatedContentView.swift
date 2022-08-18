//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

struct AuthenticatedContentView: View {
	@AppStorage(Preferences.authenticatedAccounts) var accounts
	@State var signInModel = SignInViewModel()

	var iOSContent: some View {
		TabView {
			NavigationView {
				ProjectsListView()
					.navigationTitle("Projects")
			}.tabItem {
				Label("Projects", systemImage: "folder")
			}

			NavigationView {
				DeploymentListView()
					.navigationTitle("Deployments")
			}
			.tabItem {
				Label("Deployments", systemImage: "list.bullet")
			}

			NavigationView {
				AccountListView()
					.navigationTitle("Account")
			}
			.tabItem {
				Label("Account", systemImage: "person.crop.circle")
			}
		}
	}

	var largeScreenContent: some View {
		NavigationView {
			List {
				ForEach(accounts) { account in
					let session = VercelSession(account: account)
					
					Section {
						NavigationLink(destination: ProjectsListView().navigationTitle("Projects").environmentObject(session)) {
							Label("Projects", systemImage: "folder")
						}

						NavigationLink(destination: DeploymentListView().navigationTitle("Deployments").environmentObject(session)) {
							Label("Deployments", systemImage: "list.bullet")
						}
					} header: {
						Label {
							Text(account.name ?? account.username)
						} icon: {
							VercelUserAvatarView(account: account, size: 24)
						}
					}.contextMenu {
						Button(role: .destructive) {
							VercelSession.deleteAccount(id: account.id)
						} label: {
							Label("Delete Account", systemImage: "trash")
						}
					}
				}
			}
			.navigationTitle("Zeitgeist")

			ProjectsListView()
				.navigationTitle("Projects")
			PlaceholderView(forRole: .ProjectDetail)
				.navigationTitle("Project Details")
		}
	}

	var body: some View {
		#if os(iOS)
			if UIDevice.current.userInterfaceIdiom == .phone {
				iOSContent
			} else {
				largeScreenContent
			}
		#else
			largeScreenContent
		#endif
	}
}

struct AuthenticatedContentView_Previews: PreviewProvider {
	static var previews: some View {
		AuthenticatedContentView()
	}
}
