//
//  VercelAPI.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 10/04/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

struct VercelAPIResponse {
  struct Deployments: Decodable {
    public var deployments: [Deployment] = []
  }
  
  struct Projects: Decodable {
    public var projects: [Project] = []
  }
  
  struct User: Decodable {
    public var user: VercelUser
  }
  
  typealias Team = VercelAccount
}
