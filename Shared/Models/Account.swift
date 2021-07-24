//
//  Account.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 24/07/2021.
//

import Foundation

extension Account.ID {
  var isTeam: Bool {
    self.starts(with: "team_")
  }
}

struct Account: Codable, Identifiable {
  typealias ID = String
  var id: ID
  var uid: String?
  var avatar: String?
  var name: String
  
  var isTeam: Bool {
    id.isTeam
  }
  
  init(from decoder: Decoder) throws {
    if let team = try? Team(from: decoder) {
      self.id = team.id
      self.avatar = team.avatar
      self.name = team.name
    } else {
      let response = try User.NetworkResponse(from: decoder)
      let user = response.user
      self.id = user.id
      self.avatar = user.avatar
      self.name = user.name
    }
  }
  
  init(id: String, avatar: String?, name: String) {
    self.id = id
    self.avatar = avatar
    self.name = name
  }
  
  static let mockData = Account(id: "", avatar: nil, name: "Daniel Eden")
}

struct User: Codable {
  var id: String
  var name: String
  var avatar: String?
  
  enum CodingKeys: String, CodingKey {
    case id = "uid"
    case name, avatar
  }
  
  struct NetworkResponse: Codable {
    var user: User
  }
}

struct Team: Codable {
  var id: String
  var name: String
  var avatar: String?
  
  var isTeam: Bool {
    id.isTeam
  }
}
