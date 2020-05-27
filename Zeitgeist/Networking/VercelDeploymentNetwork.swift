//
//  VercelDeploymentNetwork.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

struct VercelDeploymentNetwork: Network {
  var decoder: JSONDecoder = JSONDecoder()
  var environment: NetworkEnvironment = .vercel
}
