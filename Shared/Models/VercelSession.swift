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
  @AppStorage(Preferences.authenticatedAccounts)
  private var authenticatedAccounts {
    didSet {
      if authenticatedAccounts.count == 1,
         let firstAccount = authenticatedAccounts.first {
        account = firstAccount
      } else if !authenticatedAccounts.contains(where: { $0 == account }) {
        account = authenticatedAccounts.first
      }
      
      Task { account = await loadAccount() }
    }
  }
  
  @Published var account: VercelAccount?
  
  var authenticationToken: String? {
    guard let account = account else {
      return nil
    }

    return KeychainItem(account: account.id).wrappedValue
  }
  
  var isAuthenticated: Bool {
    account != nil && authenticationToken != nil
  }
  
  // Assume accounts are authorized unless proven otherwise
  @Published private(set) var isAuthorized = true
  
  @MainActor
  func loadAccount(fromCache: Bool = false) async -> VercelAccount? {
    do {
      guard let account = account, authenticationToken != nil else {
        return nil
      }

      var request = VercelAPI.request(for: .account(id: account.id), with: account.id)
      try signRequest(&request)
      
      if fromCache,
         let cachedResponse = URLCache.shared.cachedResponse(for: request),
         let decodedFromCache = try? JSONDecoder().decode(VercelAccount.self, from: cachedResponse.data) {
        return decodedFromCache
      }
      
      let (data, response) = try await URLSession.shared.data(for: request)
      
      switch (response as! HTTPURLResponse).statusCode {
      case 200..<300:
        isAuthorized = true
        break
      case 401...403, 409, 410, 428:
        isAuthorized = false
        return nil
      default:
        return nil
      }

      return try JSONDecoder().decode(VercelAccount.self, from: data)
    } catch {
      print(error)
      return nil
    }
  }
  
  func signRequest(_ request: inout URLRequest) throws {
    guard let authenticationToken = authenticationToken else {
      throw SessionError.notAuthenticated
    }

    request.addValue("Bearer \(authenticationToken)", forHTTPHeaderField: "Authorization")
  }
}

extension VercelSession {
  static func addAccount(id: String, token: String) async {
    guard id != .NullValue else { return }
    
    KeychainItem(account: id).wrappedValue = token
    
    var request: URLRequest
    
    if id.isTeam {
      request = URLRequest(url: URL(string: "https://api.vercel.com/v2/teams/\(id)?teamId=\(id)")!)
    } else {
      request = URLRequest(url: URL(string: "https://api.vercel.com/v2/user")!)
    }
    
    do {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      let (data, _) = try await URLSession.shared.data(for: request)
      let decoded = try JSONDecoder().decode(VercelAccount.self, from: data)
      
      DispatchQueue.main.async {
        Preferences.accounts.append(decoded)
        Preferences.accounts = Preferences.accounts.removingDuplicates()
      }
    } catch {
      print("Encountered an error when adding account with ID \(id)")
      print(error)
    }
  }
  
  static func deleteAccount(id: String) {
    let keychain = KeychainItem(account: id)
    keychain.wrappedValue = nil
    
    withAnimation { Preferences.accounts.removeAll { id == $0.id } }
  }
}
