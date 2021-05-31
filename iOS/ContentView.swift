//
//  ContentView.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

struct ContentView: View {
  @EnvironmentObject var session: Session
  @State var initialAccountID: String?
  
  var body: some View {
    NavigationView {
      AccountListView()
      if session.authenticatedAccountIds.isEmpty {
        VStack {
          PlaceholderView(forRole: .NoAccounts)
          AddAccountButton(label: "Add a Vercel Account")
        }
      } else if let accountID = initialAccountID {
        DeploymentListView(accountId: accountID)
      } else {
        PlaceholderView(forRole: .DeploymentList)
      }
      PlaceholderView(forRole: .DeploymentDetail)
    }.onAppear {
      setInitialAccountView()
    }
  }
  
  func setInitialAccountView() {
    initialAccountID = session.accountId
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
