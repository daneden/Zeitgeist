//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

struct AuthenticatedContentView: View {
  @EnvironmentObject var session: VercelSession
  
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

extension AuthenticatedContentView {
  var accountId: String { session.accountId }
  var avatarId: String { session.account?.avatar ?? "" }
  var accountName: String { session.account?.name ?? "" }
  
  var toolbarItem: some ToolbarContent {
    ToolbarItem(placement: .navigation) {
      Menu {
        Button {
          print("Tapped")
        } label: {
          Label("Switch Account", systemImage: "arrow.left.arrow.right")
        }
      } label: {
        Label {
          Text(accountName)
        } icon: {
          VercelUserAvatarView(avatarID: avatarId, size: 28)
        }
      }
      .id("accountSwitcher")
    }
  }
}

struct AuthenticatedContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedContentView()
    }
}
