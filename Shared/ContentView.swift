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
  @EnvironmentObject var settings: UserDefaultsManager
  
  @State var isValidated = false
  @State var currentViewTag: String?
  @State var needsLogin = false
  
  var body: some View {
    NavigationView {
      if isValidated && !needsLogin {
        SidebarNavigation(selection: $currentViewTag)
        DeploymentsListView()
        EmptyDeploymentView()
      } else {
        Spacer()
        SessionValidationView(isValidated: $isValidated)
        Spacer()
      }
    }
    .redacted(reason: needsLogin ? .placeholder : [])
    .accentColor(Color(TColor.systemIndigo))
    .sheet(isPresented: .constant(needsLogin)) {
      LoginView().allowAutoDismiss(false)
    }
    .onAppear {
      self.needsLogin = self.settings.token == nil
      self.isValidated = false
    }
    .onReceive(self.settings.objectWillChange) {
      self.needsLogin = self.settings.token == nil
      self.isValidated = true
    }
  }
}
