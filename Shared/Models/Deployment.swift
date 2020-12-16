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
  case cancelled = "CANCELED"
}

struct DeploymentCreator: Codable, Identifiable {
    var uid: String
    var username: String
    var email: String
    
    var id: String {
        return uid
    }
}

struct Deployment: Hashable, TimelineEntry, Decodable {
  var project: String
  var id: String
  var createdAt: Int
  
  // `date` is required to conform to `TimelineEntry`
  var date: Date {
    return Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
  }
  
  var state: DeploymentState
  var urlString: String
  
  var url: URL {
    URL(string: "https://\(urlString)")!
  }
  
  var creator: DeploymentCreator
  var meta: AnyCommit?
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(state)
  }
  
  enum CodingKeys: String, CodingKey {
    case project = "name"
    case urlString = "url"
    case createdAt = "created"
    case id = "uid"
    
    case state, creator, meta
  }
  
  static func == (lhs: Deployment, rhs: Deployment) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}
