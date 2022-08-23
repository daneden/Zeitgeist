//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

struct AuthenticatedContentView: View {
	@AppStorage(Preferences.authenticatedAccounts) private var accounts
	
	@State private var signInModel = SignInViewModel()
	@State private var presentSettingsView = false

	var body: some View {
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
						HStack {
							Label {
								Text(account.name ?? account.username)
							} icon: {
								VercelUserAvatarView(account: account, size: 24)
							}
							
							Spacer()
							
							Button {
								VercelSession.deleteAccount(id: account.id)
							} label: {
								Label("Delete Account", systemImage: "minus.circle")
									.labelStyle(.iconOnly)
							}
						}
					}
				}
			}
			.navigationTitle("Zeitgeist")
			.toolbar {
				ToolbarItem {
					Button {
						signInModel.signIn()
					} label: {
						Label("Add Account", systemImage: "plus.circle")
					}
				}
					
				ToolbarItem(placement: .navigation) {
					Button {
						presentSettingsView = true
					} label: {
						Label("More", systemImage: "ellipsis.circle")
					}
					.sheet(isPresented: $presentSettingsView) {
						SettingsView()
					}
				}
			}

			if let account = accounts.first,
				 let session = VercelSession(account: account) {
				ProjectsListView()
					.environmentObject(session)
					.navigationTitle("Projects")
				PlaceholderView(forRole: .ProjectDetail)
					.navigationTitle("Project Details")
			}
		}
	}
}

struct AuthenticatedContentView_Previews: PreviewProvider {
	static var previews: some View {
		AuthenticatedContentView()
	}
}
