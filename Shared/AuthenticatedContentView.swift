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
	@State private var removeAccountDialogVisible = false
	@State private var sidebarSelection: SidebarNavigationValue?
	
	@ToolbarContentBuilder
	var toolbarContent: some ToolbarContent {
		ToolbarItem {
			Button {
				Task { await signInModel.signIn() }
			} label: {
				Label("Add Account", systemImage: "plus.circle")
			}
		}
		
		#if os(iOS)
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
		#endif
	}

	var body: some View {
		if #available(iOS 16.0, macOS 16.0, *) {
			NavigationSplitView {
				List(accounts, selection: $sidebarSelection) { account in
					Section {
						Label("Projects", systemImage: "folder")
							.tag(SidebarNavigationValue.projects(account: account))
						
						Label("Deployments", systemImage: "list.bullet")
							.tag(SidebarNavigationValue.deployments(account: account))
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
				.toolbar {
					toolbarContent
				}
				.navigationTitle("Zeitgeist")
			} content: {
				switch sidebarSelection {
				case .none:
					Text("Select an account")
				case .some(let wrapped):
					NavigationStack {
						switch wrapped {
						case .projects(let account):
							ProjectsListView()
								.environmentObject(VercelSession(account: account))
						case .deployments(let account):
							DeploymentListView()
								.environmentObject(VercelSession(account: account))
						}
					}
				}
			} detail: {
				NavigationStack {
					PlaceholderView(forRole: .ProjectDetail)
				}
			}
			.onAppear {
				if let account = accounts.first {
					sidebarSelection = .projects(account: account)
				}
			}

		} else {
			NavigationView {
				List {
					ForEach(accounts) { account in
						let session = VercelSession(account: account)
						
						Section {
							NavigationLink {
								ProjectsListView()
									.environmentObject(session)
							} label: {
								Label("Projects", systemImage: "folder")
							}
							
							NavigationLink {
								DeploymentListView()
									.environmentObject(session)
							} label: {
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
					toolbarContent
				}
				
				if let account = accounts.first,
					 let session = VercelSession(account: account) {
					ProjectsListView()
						.environmentObject(session)
						.navigationTitle("Projects")
				} else {
					PlaceholderView(forRole: .NoProjects)
				}
				
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
