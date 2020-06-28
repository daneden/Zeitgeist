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
  #if os(macOS)
  var padding = 16.0 as CGFloat
  #else
  var padding = 0 as CGFloat
  #endif

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      #if os(macOS)
      UpdaterView()
      #endif
      if self.settings.token == nil {
        VStack {
          Spacer()
          VStack {
            Image("splashIcon")
            Text("Zeitgeist")
              .fontWeight(.bold)
              .font(Font.system(.title, design: .rounded))
          }.padding(.bottom, 24)
          
          Form {
            Section(header: Text("Vercel Access Token"),
                    footer:
                      VStack(alignment: .leading, spacing: 4) {
                        Text("You'll need to create an access token on Vercel's website to use Zeitgeist.")
                          .foregroundColor(.secondary)
                        Link("Create Token", destination: URL(string: "https://vercel.com/account/tokens")!)
                          .foregroundColor(.accentColor)
                      }.font(.footnote)
            ) {
              SecureField("Enter Access Token", text: $inputValue)

              Button(action: { self.settings.token = self.inputValue }, label: {
                Text("loginButton")
              })
                .disabled(inputValue.isEmpty)
            }
            
          }
          
          Spacer()
          Spacer()
        }
        .padding(.all, padding)
      } else if let fetcher = VercelFetcher(settings, withTimer: true) {
        HeaderView()
          .environmentObject(fetcher)
        DeploymentsListView()
          .environmentObject(fetcher)
        FooterView()
        
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
