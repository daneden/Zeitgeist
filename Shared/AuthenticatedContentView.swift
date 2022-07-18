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
      }.tabItem {
        Label("Projects", systemImage: "folder")
      }
      
      NavigationView {
        DeploymentListView(accountId: session.accountId)
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
}

struct AuthenticatedContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedContentView()
    }
}
