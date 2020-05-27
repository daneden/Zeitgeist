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
  @State var inputValue = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      UpdaterView()
      if self.settings.token == nil {
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
            Text("tokenInputLabel")

            TextField("tokenInputPlaceholder", text: $inputValue)
              .textFieldStyle(RoundedBorderTextFieldStyle())
              .font(.system(.caption, design: .monospaced))

            HStack {
              Button(action: self.saveToken, label: {
                HStack {
                  Spacer()
                  Text("loginButton")
                  Spacer()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
              })
                .disabled($inputValue.wrappedValue.isEmpty)
              Spacer()
              Button(action: self.openTokenPage) {
                Text("createTokenButton")
              }.buttonStyle(LinkButtonStyle())

            }
          }
          Spacer()
        }
        .padding()
      } else {
        HeaderView()
        DeploymentsListView()
          .environmentObject(VercelViewModel(with: VercelDeploymentNetwork()))
        FooterView()
        
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  func openTokenPage() {
    let url = URL(string: "https://zeit.co/account/tokens")!
    NSWorkspace.shared.open(url)
  }

  func saveToken() {
    self.settings.token = inputValue
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
