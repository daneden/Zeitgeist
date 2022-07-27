//
//  AuthenticatedContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 11/07/2022.
//

import SwiftUI

struct AuthenticatedContentView: View {
  @EnvironmentObject var session: VercelSession
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
        Menu {
          Picker(selection: $session.account, label: Text("Selected Account")) {
            ForEach(Preferences.accounts, id: \.self) { account in
              AccountListRowView(account: account)
                .tag(account)
            }
          }
          
          Button {
            signInModel.signIn()
          } label: {
            Label("Add Account", systemImage: "person.badge.plus")
          }
        } label: {
          AccountListRowView(account: session.account)
            .id(session.account)
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
