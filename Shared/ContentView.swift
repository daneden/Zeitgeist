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
    Group {
      if self.settings.token == nil {
        Form {
          Spacer()
          VStack {
            Image("splashIcon")
            Text("Zeitgeist")
              .fontWeight(.bold)
              .font(.title)
          }.padding(.bottom, 24)
          
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
        .padding(.all, padding)
      } else if let fetcher = VercelFetcher(settings, withTimer: true) {
        NavigationView {
          DeploymentsListView()
            .frame(idealWidth: 250, maxWidth: .infinity)
            .environmentObject(fetcher)
            .navigationTitle(Text("Deployments"))
            .toolbar {
              ToolbarItem {
                NavigationLink(destination: SettingsView()) {
                  Label("Settings", systemImage: "slider.horizontal.3").labelStyle(IconOnlyLabelStyle())
                }
              }
            }
          
          EmptyDeploymentView()
        }.frame(idealWidth: .infinity, maxWidth: .infinity, idealHeight: .infinity, maxHeight: .infinity)
      }
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
