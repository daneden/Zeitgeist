//
//  AccountManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 10/04/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

struct VercelUser: Codable, Hashable {
  var id: String
  var name: String
  var avatar: String
  var email: String
  
  enum CodingKeys: String, CodingKey {
    case id = "uid"
    
    case name, avatar, email
  }
}

struct VercelAccount: Codable, Hashable {
  var id: String
  var name: String?
  var avatar: String?
  
  var isTeam: Bool {
    id.starts(with: "team_")
  }
  
  var user: VercelUser?
  
  enum CodingKeys: String, CodingKey {
    case id
    
    case name, avatar
  }
}

class AccountManager: ObservableObject {
  static let shared = AccountManager()
  
  @Published var accounts = [VercelAccount]()
  @Published var currentAccount: VercelAccount?
}
