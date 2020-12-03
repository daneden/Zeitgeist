//
//  SessionValidationView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct SessionValidationView: View {
  let settings = UserDefaultsManager.shared
  @Binding var isValidated: Bool
  
  var body: some View {
    if !isValidated {
      ProgressView(label: {
        Text("Logging in...")
      }).onAppear {
        validateSession()
      }
    }
  }
  
  func validateSession() {
    if let token = self.settings.token {
      let url = URL(string: "https://api.vercel.com/www/user")!
      var request = URLRequest(url: url)
      request.allHTTPHeaderFields = ["Authorization": "Bearer \(token)"]
      
      let task = URLSession.shared.dataTask(with: request) {_, response, _ in
        if let httpResponse = response as? HTTPURLResponse {
          switch httpResponse.statusCode {
          // a-ok
          case 200:
            self.isValidated = true
          // bad token/permission
          case 403:
            self.isValidated = false
            DispatchQueue.main.async {
              self.settings.token = nil
            }
          // all other (unknown) cases, such as server errors
          // TODO: Stub out additional API response codes
          default:
            self.isValidated = false
          }
        }
      }
      
      task.resume()
    } else {
      self.isValidated = false
    }
  }
}

struct SessionValidationView_Previews: PreviewProvider {
  @State var isValidated = false
    static var previews: some View {
      SessionValidationView(isValidated: .constant(false))
    }
}
