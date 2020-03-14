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
        VStack {
          Spacer()
          VStack {
            Image("splashIcon")
            Text("Zeitgeist")
              .fontWeight(.bold)
              .font(Font.system(.title, design: .rounded))
          }
          Spacer()
          VStack(alignment: .leading) {
            Text("Enter Zeit access token:")
            
            TextField("Token", text: $inputValue)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .font(.system(.caption, design: .monospaced))
            
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
          Spacer()
        }
        .padding()
      } else {
        DeploymentsListView()
          .environmentObject(ZeitDeploymentsViewModel(with: ZeitDeploymentNetwork(enviroment: .zeit)))
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
  }
}


struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
