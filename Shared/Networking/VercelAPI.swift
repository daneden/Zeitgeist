//
//  VercelAPI.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/06/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

var APP_VERSION: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

enum FetchState {
  case loading
  case finished
  case error
  case idle
}

struct VercelTeamsAPIResponse: Decodable {
  public var teams: [VercelTeam] = [VercelTeam]()
}

enum VercelRoute: String {
  case teams = "v1/teams"
  case deployments = "v6/now/deployments"
  case user = "www/user"
}
