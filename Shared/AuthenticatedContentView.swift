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
    if UIDevice.current.userInterfaceIdiom == .phone {
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
    } else {
      NavigationView {
        List {
          NavigationLink(destination: ProjectsListView().navigationTitle("Projects")) {
            Label("Projects", systemImage: "folder")
          }
          NavigationLink(destination: DeploymentListView().navigationTitle("Deployments")) {
            Label("Deployments", systemImage: "list.bullet")
          }
          NavigationLink(destination: AccountView().navigationTitle("Account")) {
            Label("Account", systemImage: "person.crop.circle")
          }
        }
        .navigationTitle("Zeitgeist")
        
        ProjectsListView()
        PlaceholderView(forRole: .ProjectDetail)
      }
    }
  }
}

struct AuthenticatedContentView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedContentView()
    }
}
