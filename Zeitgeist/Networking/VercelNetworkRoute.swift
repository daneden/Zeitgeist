//
//  ZeitDeploymentNetworkRoute.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Cocoa

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
  
  var queryItems: [URLQueryItem]? {
    switch self {
    case .deployments:
      let currentTeam = UserDefaultsManager().currentTeam
      return ( currentTeam == nil || currentTeam == "0") ? nil : [
        URLQueryItem(name: "teamId", value: UserDefaultsManager().currentTeam.unsafelyUnwrapped)
      ]
    }
  }

  var headers: [String: String]? {
    let appDelegate = NSApplication.shared.delegate as? AppDelegate
    switch self {
    default:
      return appDelegate?.getVercelHeaders()
    }
  }
}
