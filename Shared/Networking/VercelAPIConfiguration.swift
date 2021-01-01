//
//  VercelAPIConfiguration.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

class VercelAPIConfiguration: Codable {
  public let clientId: String = "oac_j50L1tLSVzBpEv1gXEVDdR3g"
  
  public enum CodingKeys: String, CodingKey {
    case clientId = "client_id"
  }
}
