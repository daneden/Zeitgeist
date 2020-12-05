//
//  Deployment.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 02/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import WidgetKit

enum DeploymentState: String, Codable {
  case ready = "READY"
  case queued = "QUEUED"
  case error = "ERROR"
  case building = "BUILDING"
  case normal = "NORMAL"
  case offline = "OFFLINE"
}

struct Deployment: Hashable, TimelineEntry {
  var project: String
  var id: String
  var createdAt: Date
  
  var date: Date {
    return self.createdAt
  }
  
  var state: DeploymentState
  var url: URL
  var creator: VercelDeploymentUser
  var svnInfo: GitCommit?
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(state)
  }
  
  static func == (lhs: Deployment, rhs: Deployment) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}
