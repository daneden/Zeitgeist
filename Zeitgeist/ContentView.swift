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
  @ObservedObject var settings = UserDefaultsManager()
  @State var inputValue = ""
  var body: some View {
    VStack(alignment: .leading) {
      if(self.$settings.token.wrappedValue == nil) {
        VStack(alignment: .leading) {
          Text("Enter Zeit access token:")
          
            TextField("Token", text: $inputValue)
          HStack {
            Button(action: self.saveToken, label: {
              HStack {
                Spacer()
                Text("Log In")
                Spacer()
              }
              .frame(minWidth: 0, maxWidth: .infinity)
            })
              .disabled($inputValue.wrappedValue == "")
            Spacer()
            Button(action: self.openTokenPage) {
              Text("Create Token")
            }.buttonStyle(LinkButtonStyle())
          
          }
        }
      .padding()
      } else {
        DeploymentsListView()
          .environmentObject(ZeitDeploymentsViewModel(with: ZeitDeploymentNetwork(enviroment: .deployments)))
          .environmentObject(settings)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
  
  func openTokenPage() -> Void {
    let url = URL(string: "https://zeit.co/account/tokens")!
    NSWorkspace.shared.open(url)
  }
  
  func saveToken() -> Void {
    self.settings.token = inputValue
    settings.objectWillChange.send()
  }
}

class UserDefaultsManager: ObservableObject {
  @Published var token: String? = UserDefaults.standard.string(forKey: "ZeitToken") {
    didSet { UserDefaults.standard.set(self.token, forKey: "ZeitToken") }
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
