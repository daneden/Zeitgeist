//
//  SignInViewModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI
import Combine
import AuthenticationServices

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
  private var subscriptions: [AnyCancellable] = []
  
  func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
    return ASPresentationAnchor()
  }
  
  func signIn() {
    let signInPromise = Future<URL, Error> { completion in
      let apiData = VercelAPIConfiguration()
      let authUrl = VercelURLAuthenticationBuilder(clientID: apiData.clientId)()
      
      let authSession = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: "https") { (url, error) in
        if let error = error {
          completion(.failure(error))
        } else if let url = url {
          completion(.success(url))
        }
      }
      
      authSession.presentationContextProvider = self
      authSession.prefersEphemeralWebBrowserSession = true
      authSession.start()
    }
    
    signInPromise.sink { (completion) in
      switch completion {
      case .failure(let error):
        print("auth failed for reason: \(error)")
      default: break
      }
    } receiveValue: { (url) in
      self.processResponseURL(url: url)
    }
    .store(in: &subscriptions)
  }
  
  func processResponseURL(url: URL) {
    let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
    
    if let queryItems = components?.queryItems,
       let token = queryItems.filter({ $0.name  == "token" }).first?.value {
      Session.shared.token = token
    } else {
      print("Something went wrong!")
    }
  }
}
