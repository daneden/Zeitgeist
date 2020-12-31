//
//  Project.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

struct Project: Decodable, Hashable {
  var id: String
  var name: String
  var updatedAt: Int
  var link: SVNLink?
//  var latestDeployments: [Deployment]?
  
  var updated: Date {
    Date(timeIntervalSince1970: Double(updatedAt / 1000))
  }
}

struct SVNLink: Codable, Hashable {
  var type: GitSVNProvider
}
