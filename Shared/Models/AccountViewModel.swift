//
//  AccountViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import SwiftUI

struct Account: Codable, Identifiable {
  typealias ID = String
  var id: ID
  var isTeam: Bool { id.isTeam }
  var avatar: String?
  var name: String
}

extension Account.ID {
  var isTeam: Bool {
    self.starts(with: "team_")
  }
}

class AccountViewModel: LoadableObject {
  private var decoder = JSONDecoder()
  var cache: Cache
  
  @AppStorage("refreshFrequency") var refreshFrequency: Double = 5.0
  typealias Output = Account
  
  @Published private(set) var state: LoadingState<Output> = .idle {
    didSet {
      if case .loaded(let account) = state {
        value = account
      }
    }
  }
  @Published private(set) var value: Output?
  
  private let accountId: Account.ID
  
  init(accountId: Account.ID) {
    self.accountId = accountId
    self.cache = Cache()
    
    if let cachedData = cache[cacheKey],
       let decoded = try? JSONDecoder().decode(Output.self, from: cachedData) {
      state = .loaded(decoded)
    }
  }
  
  func load() async {
    switch state {
    case .loaded(_):
      break
    default:
      state = .loading
    }
    
    let isTeam = accountId.starts(with: "team_")
    let urlPath = isTeam ? "v1/teams/\(accountId)" : "www/user"
    guard let url = URL(string: "https://api.vercel.com/\(urlPath)?teamId=\(isTeam ? accountId : "")&userId=\(accountId)") else {
      return
    }
    
    guard let token = KeychainItem(account: accountId).wrappedValue else {
      return
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let watcher = URLRequestWatcher(urlRequest: request, delay: Int(refreshFrequency))
    
    do {
      for try await data in watcher {
        if let newData = handleResponseData(data: data, isTeam: accountId.starts(with: "team_")) {
          DispatchQueue.main.async {
            self.state = .loaded(newData)
          }
          
          cache[cacheKey] = data
        }
      }
    } catch {
      print(error.localizedDescription)
    }
  }
}

extension AccountViewModel {
  func handleResponseData(data: Data, isTeam: Bool) -> Account? {
    var account: Account
    
    if isTeam {
      guard let decoded = try? self.decoder.decode(Team.self, from: data) else {
        return nil
      }
      
      account = Account(id: decoded.id, avatar: decoded.avatar, name: decoded.name)
    } else {
      guard let decoded = try? self.decoder.decode(UserResponse.self, from: data) else {
        return nil
      }
      
      account = Account(id: decoded.user.id, avatar: decoded.user.avatar, name: decoded.user.name)
    }
    
    return account
  }
}


extension AccountViewModel {
  private var cacheKey: String {
    "__cache__account-\(accountId)"
  }
}
