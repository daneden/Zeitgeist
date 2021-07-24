//
//  Alias.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 24/07/2021.
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

extension Alias {
  struct NetworkResponse: Codable {
    var result: [Alias]
    
    enum CodingKeys: String, CodingKey {
      case result = "aliases"
    }
  }
}
