//
//  VercelAuthenticationURLBuilder.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

class VercelURLAuthenticationBuilder {
  let domain: String
  let clientID: String
  let uid = UUID()
  
  init(domain: String = "vercel.com", clientID: String) {
    self.domain = domain
    self.clientID = clientID
  }
  
  var url: URL {
    var components = URLComponents()
    components.scheme = "https"
    components.host = domain
    components.path = "/integrations/zeitgeist/new"
    components.queryItems = [
      "client_id": clientID,
      "v": "2"
    ].map { URLQueryItem(name: $0, value: $1)}
    
    return components.url!
  }
  
  func callAsFunction() -> URL {
    url
  }
}
