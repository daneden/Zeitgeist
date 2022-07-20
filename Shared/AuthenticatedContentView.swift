//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

struct AuthenticatedContentView: View {
  @EnvironmentObject var session: VercelSession
  
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
        AccountView()
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
        Menu {
          Picker(selection: $session.accountId, label: Text("Selected Account")) {
            ForEach(Preferences.authenticatedAccountIds, id: \.self) { accountId in
              AccountListRowView(accountId: accountId)
                .tag(accountId)
            }
          }
        } label: {
          AccountListRowView(accountId: session.accountId)
            .id(session.accountId)
        }
        
        NavigationLink(destination: ProjectsListView().navigationTitle("Projects")) {
          Label("Projects", systemImage: "folder")
        }
        
        NavigationLink(destination: DeploymentListView().navigationTitle("Deployments")) {
          Label("Deployments", systemImage: "list.bullet")
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
