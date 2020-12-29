//
//  Deployment.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 02/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import WidgetKit

enum DeploymentTarget: String, Codable, CaseIterable {
  case production, staging
}

enum DeploymentState: String, Codable, CaseIterable {
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
  var isMockDeployment: Bool?
  var project: String
  var id: String
  var target: DeploymentTarget?
  private var createdAt: Int = Int(Date().timeIntervalSince1970) / 1000
  
  // `date` is required to conform to `TimelineEntry`
  var date: Date {
    return Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
  }
  
  var state: DeploymentState
  private var urlString: String = "vercel.com"
  
  var url: URL {
    URL(string: "https://\(urlString)")!
  }
  
  var creator: DeploymentCreator
  var commit: AnyCommit?
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(state)
  }
  
  enum CodingKeys: String, CodingKey {
    case project = "name"
    case urlString = "url"
    case createdAt = "created"
    case id = "uid"
    case commit = "meta"
    
    case state, creator, target
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    project = try container.decode(String.self, forKey: .project)
    urlString = try container.decode(String.self, forKey: .urlString)
    createdAt = try container.decode(Int.self, forKey: .createdAt)
    id = try container.decode(String.self, forKey: .id)
    commit = try? container.decode(AnyCommit.self, forKey: .commit)
    state = try container.decode(DeploymentState.self, forKey: .state)
    creator = try container.decode(DeploymentCreator.self, forKey: .creator)
    target = try? container.decode(DeploymentTarget.self, forKey: .target)
  }
  
  static func == (lhs: Deployment, rhs: Deployment) -> Bool {
    return lhs.hashValue == rhs.hashValue
  }
}
