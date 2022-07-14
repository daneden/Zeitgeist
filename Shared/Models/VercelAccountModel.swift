//
//  AccountViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

protocol Account: Decodable {
  var id: String { get }
  var name: String { get }
  var avatar: String? { get }
}

struct VercelAccount: Account, Decodable, Identifiable {
  typealias ID = String
  
  private var wrapped: Account
  
  var id: ID { wrapped.id }
  var isTeam: Bool { id.isTeam }
  var avatar: String? { wrapped.avatar }
  var name: String { wrapped.name }
  
  init(from decoder: Decoder) throws {
    if let user = try? VercelUser.APIResponse(from: decoder).user {
      wrapped = user
    } else if let team = try? VercelTeam(from: decoder) {
      wrapped = team
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode Vercel account")
      )
    }
  }
}

extension VercelAccount.ID {
  var isTeam: Bool {
    self.starts(with: "team_")
  }
  
  static var NullValue = "NULL"
}

fileprivate struct VercelUser: Account, Codable {
  var id: String
  var name: String
  var avatar: String?
}

extension VercelUser {
  struct APIResponse: Codable {
    var user: VercelUser
  }
}

fileprivate struct VercelTeam: Account, Codable {
  var id: String
  var name: String
  var avatar: String?
}

//extension AccountViewModel {
//  func loadCachedData() -> VercelAccount? {
//    if let cachedResults = URLCache.shared.cachedResponse(for: request),
//       let decodedResults = handleResponseData(data: cachedResults.data, isTeam: accountId.isTeam) {
//      return decodedResults
//    }
//
//    return nil
//  }
//}
