//
//  ContentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI
import Combine

struct ContentView: View {
  #if os(macOS)
  var horizontalSizeClass: SizeClassHack = .regular
  #else
  @Environment(\.horizontalSizeClass) var horizontalSizeClass
  #endif
  
  @AppStorage("isSessionValidated") var isValidated = false
  @AppStorage("userNeedsLogin") var needsLogin = false
  @ObservedObject var session = Session.shared
  
  var body: some View {
    NavigationView {
      if isValidated && !needsLogin {
        SidebarNavigation()
        DeploymentsListView()
        EmptyDeploymentView()
      } else {
        Spacer()
        SessionValidationView(isValidated: $isValidated)
        Spacer()
      }
    }
    .redacted(reason: needsLogin ? .placeholder : [])
    .sheet(isPresented: $needsLogin) {
      LoginView().allowAutoDismiss(false)
    }
    .onAppear {
      DispatchQueue.main.async {
        self.needsLogin = session.accounts.isEmpty
        self.isValidated = !self.needsLogin
      }
    }
    .onReceive(session.objectWillChange) {
      DispatchQueue.main.async {
        self.needsLogin = session.accounts.isEmpty
        self.isValidated = !self.needsLogin
      }
    }
  }
}
