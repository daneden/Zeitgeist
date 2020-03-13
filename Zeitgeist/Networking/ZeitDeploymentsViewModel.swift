//
//  ZeitDeploymentsViewModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine

enum ZeitDeploymentState: String, Codable {
  case ready = "READY"
  case queued = "QUEUED"
  case error = "ERROR"
  case building = "BUILDING"
}

struct ZeitUser: Decodable, Identifiable {
  public var id: String
  public var email: String
  public var username: String
  public var githubLogin: String
  
  enum CodingKeys: String, CodingKey {
    case id = "uid"
    case email = "email"
    case username = "username"
    case githubLogin = "githubLogin"
  }
}

struct ZeitDeployment: Decodable, Identifiable {
  public var id: String
  public var name: String
  public var url: String
  public var created: Int
  public var state: ZeitDeploymentState
  public var creator: ZeitUser
  
  public var relativeTimestamp: String {
    let date = Date(timeIntervalSince1970: TimeInterval(exactly: created / 1000)!)
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    let relativeDate = formatter.localizedString(for: date, relativeTo: Date())
    
    return relativeDate
  }
  
  public var absoluteURL: String {
    return "https://\(url)"
  }
  
  enum CodingKeys: String, CodingKey {
    case id = "uid"
    case name = "name"
    case url = "url"
    case created = "created"
    case state = "state"
    case creator = "creator"
  }
}

struct ZeitDeploymentsArray: Decodable {
  public var deployments: [ZeitDeployment]
  
  enum CodingKeys: String, CodingKey {
    case deployments = "deployments"
  }
}

class ZeitDeploymentsViewModel: NetworkViewModel, ObservableObject {
  var resource: Resource<ZeitDeploymentsArray> = .loading
  var network: Network
  
  var route: NetworkRoute = ZeitDeploymentNetworkRoute.deployments
  
  var bag: Set<AnyCancellable> = Set<AnyCancellable>()
  
  init(with network: Network) {
    self.network = network
  }
}
