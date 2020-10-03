//
//  LoginView.swift
//  ZeitgeistTests
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct LoginView: View {
  @State var inputValue = ""
  @EnvironmentObject var settings: UserDefaultsManager
  #if os(macOS)
  var padding = 16.0 as CGFloat
  #else
  var padding = 0 as CGFloat
  #endif
  
  var body: some View {
    Form {
      ZeitgeistLogo()
      
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
    .frame(maxWidth: 400)
  }
}
