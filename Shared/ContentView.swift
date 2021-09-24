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
  @State var onboardingViewVisible = false
  
  var body: some View {
    NavigationView {
      AccountListView()
      if session.authenticatedAccountIds.isEmpty {
        VStack {
          PlaceholderView(forRole: .NoAccounts)
            .padding(.bottom)
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
    }.onChange(of: session.authenticatedAccountIds) { _ in
      setInitialAccountView()
    }.sheet(isPresented: $onboardingViewVisible) {
      #if !os(macOS)
      OnboardingView().allowAutoDismiss(false)
      #else
      OnboardingView()
      #endif
    }
    .symbolRenderingMode(.multicolor)
  }
  
  func setInitialAccountView() {
    initialAccountID = session.accountId
    onboardingViewVisible = session.accountId == nil
  }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
