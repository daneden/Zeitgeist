//
//  Session.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import SwiftUI
import Combine

enum SessionError: Error {
  case notAuthenticated
}

extension SessionError: CustomStringConvertible {
  var description: String {
    switch self {
    case .notAuthenticated:
      return "The chosen account has not been authenticated on this device"
    }
  }
}

class VercelSession: ObservableObject {
  @AppStorage(Preferences.authenticatedAccountIds)
  private var authenticatedAccountIds {
    didSet {
      if authenticatedAccountIds.count == 1,
         let firstAccount = authenticatedAccountIds.first {
        accountId = firstAccount
      } else if !authenticatedAccountIds.contains(where: { $0 == accountId }) {
        accountId = authenticatedAccountIds.first ?? .NullValue
      }
    }
  }
  
  @Published var accountId: VercelAccount.ID = .NullValue {
    didSet {
      Task {
        if accountId == .NullValue {
          account = nil
        } else {
          account = await loadAccount(fromCache: true)
          account = await loadAccount()
        }
      }
    }
  }
  
  @Published private(set) var account: VercelAccount?
  
  var authenticationToken: String? {
    guard accountId != .NullValue else {
      return nil
    }

    return KeychainItem(account: accountId).wrappedValue
  }
  
  var isAuthenticated: Bool {
    accountId != .NullValue && authenticationToken != nil
  }
  
  @MainActor
  func loadAccount(fromCache: Bool = false) async -> VercelAccount? {
    do {
      guard accountId != .NullValue, authenticationToken != nil else {
        return nil
      }

      var request = VercelAPI.request(for: .account(id: accountId), with: accountId)
      try signRequest(&request)
      
      if fromCache,
         let cachedResponse = URLCache.shared.cachedResponse(for: request),
         let decodedFromCache = try? JSONDecoder().decode(VercelAccount.self, from: cachedResponse.data) {
        return decodedFromCache
      }
      
      let (data, _) = try await URLSession.shared.data(for: request)

      return try JSONDecoder().decode(VercelAccount.self, from: data)
    } catch {
      print(error)
      return nil
    }
  }
  
  static func addAccount(id: String, token: String) {
    guard id != .NullValue else { return }
    
    KeychainItem(account: id).wrappedValue = token
    
    DispatchQueue.main.async {
      Preferences.accountIds.append(id)
      Preferences.accountIds = Preferences.accountIds.removingDuplicates()
    }
  }
  
  static func deleteAccount(id: String) {
    let keychain = KeychainItem(account: id)
    keychain.wrappedValue = nil
    
    withAnimation { Preferences.accountIds.removeAll { id == $0 } }
  }
  
  func signRequest(_ request: inout URLRequest) throws {
    guard let authenticationToken = authenticationToken else {
      throw SessionError.notAuthenticated
    }

    request.addValue("Bearer \(authenticationToken)", forHTTPHeaderField: "Authorization")
  }
}
