//
//  ZeitDeploymentNetworkRoute.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

enum VercelNetworkRoute {
  case deployments
}

extension VercelNetworkRoute: NetworkRoute {

  var path: String {
    switch self {
    case .deployments:
      return "/v6/now/deployments"
    }
  }

  var method: NetworkMethod {
    switch self {
    case .deployments:
      return .get
    }
  }

  var headers: [String: String]? {
    switch self {
    default:
      let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
      return [
        "Authorization": "Bearer " + (UserDefaults.standard.string(forKey: "ZeitToken") ?? ""),
        "Content-Type": "application/json",
        "User-Agent": "Zeitgeist Client \(version ?? "(Unknown Version)")"
        
      ]
    }
  }
}
