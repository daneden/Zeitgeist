//
//  Alias.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

struct Alias: Codable, Hashable {
  var uid: String
  var alias: String
  var url: URL {
    URL(string: "https://\(alias)")!
  }
  
  enum CodingKeys: String, CodingKey {
    case uid, alias
  }
}

struct AliasesResponse: Codable {
  var aliases: [Alias]
}
