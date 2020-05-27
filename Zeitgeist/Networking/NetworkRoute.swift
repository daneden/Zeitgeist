//
//  NetworkRoute.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

protocol NetworkRoute {
  var path: String { get }
  var method: NetworkMethod { get }
  var headers: [String: String]? { get }
  var queryItems: [URLQueryItem]? { get }
}

extension NetworkRoute {
  var headers: [String: String]? {
    return nil
  }
  
  var queryItems: [URLQueryItem]? {
    return nil
  }

  func create(for environment: NetworkEnvironment, append: String?) -> URLRequest {
    let url = URLComponents(string: "\(environment.rawValue)\(path)\(append ?? "")")!
    var request = URLRequest(url: url.url!)
    request.allHTTPHeaderFields = headers
    request.httpMethod = method.rawValue.uppercased()

    return request
  }
}
