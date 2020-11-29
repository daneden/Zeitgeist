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
  @State var validating = false
  @State var errorMessage = ""
  
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
        
        Button(action: { self.validateToken() }, label: {
          HStack {
            Text("loginButton")
            Spacer()
            if validating {
              ProgressView()
            }
          }
        })
        .disabled(inputValue.isEmpty || validating)
        
        if !errorMessage.isEmpty {
          Text(errorMessage).foregroundColor(Color(TColor.systemRed))
        }
      }
    }
    .padding(.all, padding)
    .frame(maxWidth: 400)
  }
  
  func validateToken() {
    self.validating = true
    self.errorMessage = ""
    
    let url = URL(string: "https://api.vercel.com/www/user")!
    var request = URLRequest(url: url)
    request.allHTTPHeaderFields = ["Authorization": "Bearer \(self.inputValue)"]

    let task = URLSession.shared.dataTask(with: request) {data, response, error in

        if let httpResponse = response as? HTTPURLResponse {
          switch httpResponse.statusCode {
          case 200:
            self.settings.token = self.inputValue
          default:
            self.errorMessage = "Invalid Vercel access token."
          }
          
          self.validating = false
        }

    }
    task.resume()
  }
}
