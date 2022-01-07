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
  
  private var request: URLRequest {
    let isTeam = accountId.isTeam
    let urlPath = isTeam ? "v1/teams/\(accountId)" : "www/user"
    let url = URL(string: "https://api.vercel.com/\(urlPath)?teamId=\(isTeam ? accountId : "")&userId=\(accountId)")!
    let token = KeychainItem(account: accountId).wrappedValue ?? ""
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    return request
  }
  
  private let accountId: Account.ID
  
  init(accountId: Account.ID) {
    self.accountId = accountId
    
    if let cachedData = loadCachedData() {
      state = .loaded(cachedData)
    }
  }
  
  func load() async {
    switch state {
    case .loaded(_):
      break
    default:
      state = .loading
    }
    
    let watcher = URLRequestWatcher(urlRequest: request, delay: Int(refreshFrequency))
    
    do {
      for try await data in watcher {
        if let newData = handleResponseData(data: data, isTeam: accountId.isTeam) {
          DispatchQueue.main.async {
            self.state = .loaded(newData)
          }
        }
      }
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func loadOnce() async -> Account? {
    do {
      let (data, _) = try await URLSession.shared.data(for: request)
      
      return handleResponseData(data: data, isTeam: accountId.isTeam)
    } catch {
      return nil
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
  func loadCachedData() -> Account? {
    if let cachedResults = URLCache.shared.cachedResponse(for: request),
       let decodedResults = handleResponseData(data: cachedResults.data, isTeam: accountId.isTeam) {
      return decodedResults
    }
    
    return nil
  }
}
