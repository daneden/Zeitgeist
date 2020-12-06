//
//  FetchVercelBuilds.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

struct VercelTeam: Decodable {
  public var id: String?
  public var name: String? = "Personal"
}

struct VercelUser: Decodable, Identifiable {
  public var id: String
  public var name: String
  public var email: String
  public var avatar: String
  
  enum CodingKeys: String, CodingKey {
    case id = "uid"
    case email = "email"
    case name = "name"
    case avatar = "avatar"
  }
}

struct VercelUserAPIResponse: Decodable {
  public var user: VercelUser
}

struct VercelDeploymentUser: Decodable, Identifiable {
  public var id: String
  public var email: String
  public var username: String
  public var githubLogin: String?
  
  enum CodingKeys: String, CodingKey {
    case id = "uid"
    case email = "email"
    case username = "username"
    case githubLogin = "githubLogin"
  }
}
