//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

struct AuthenticatedContentView: View {
  @EnvironmentObject var session: VercelSession
  
  var accountId: String { session.accountId ?? "" }
  var avatarId: String { session.account?.avatar ?? "" }
  var accountName: String { session.account?.name ?? "" }
  
  var toolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigationBarLeading) {
      Menu {
        Text("Switch Accounts")
      } label: {
        Label {
          Text(accountName)
        } icon: {
          VercelUserAvatarView(avatarID: avatarId, size: 32)
        }
      }
      .id("accountSwitcher")
    }
  }
  
  var body: some View {
    TabView {
      NavigationView {
        ProjectsListView()
          .navigationTitle("Projects")
          .toolbar { toolbarItem }
      }.tabItem {
        Label("Projects", systemImage: "folder")
      }
      
      NavigationView {
        DeploymentListView(accountId: accountId)
          .navigationTitle("Deployments")
          .toolbar { toolbarItem }
      }
      .tabItem {
        Label("Deployments", systemImage: "list.bullet")
      }
    }
  }
}

struct AuthenticatedContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedContentView()
    }
}
