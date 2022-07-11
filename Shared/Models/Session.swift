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

typealias AccountIDs = [Account.ID]

extension AccountIDs: RawRepresentable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode(AccountIDs.self, from: data)
    else {
      return nil
    }
    self = result
  }

  public var rawValue: String {
    guard let data = try? JSONEncoder().encode(self),
          let result = String(data: data, encoding: .utf8)
    else {
      return "[]"
    }
    return result
  }
}

extension SessionError: CustomStringConvertible {
  var description: String {
    switch self {
    case .notAuthenticated:
      return "The chosen account has not been authenticated on this device"
    }
  }
}

class Session: ObservableObject {
  private(set) var uuid = UUID()
  static let shared = Session()

  @AppStorage("authenticatedAccountIds", store: Preferences.store) var authenticatedAccountIds: AccountIDs = []
  @AppStorage("notificationsEnabled") var notificationsEnabled = false
  
  var accountId: String? {
    authenticatedAccountIds.first
  }

  func addAccount(id: String, token: String) {
    KeychainItem(account: id).wrappedValue = token

    DispatchQueue.main.async {
      self.authenticatedAccountIds.append(id)
      self.authenticatedAccountIds = self.authenticatedAccountIds.removingDuplicates()
    }
  }

  func deleteAccount(id: String) {
    let keychain = KeychainItem(account: id)
    keychain.wrappedValue = nil

    authenticatedAccountIds.removeAll { candidate in
      id == candidate
    }
  }
  
  func revalidate() {
    withAnimation { uuid = UUID() }
  }
}

@MainActor
class VercelSession: ObservableObject {
  @Published var accountId: Account.ID = .NullValue {
    didSet { Task { await loadAccount() } }
  }
  
  @Published var account: Account?
  
  var authenticationToken: String? {
    guard accountId != .NullValue else {
      return nil
    }

    return KeychainItem(account: accountId).wrappedValue
  }
  
  var isAuthenticated: Bool {
    accountId != .NullValue && authenticationToken != nil
  }
  
  private func loadAccount() async {
    do {
      guard accountId != .NullValue else {
        return
      }

      let request = try VercelAPI.request(for: .account(id: accountId), with: accountId)
      let (data, _) = try await URLSession.shared.data(for: request)
      
      if accountId.isTeam {
        let decoded = try JSONDecoder().decode(Team.self, from: data)
        
        account = Account(id: decoded.id, avatar: decoded.avatar, name: decoded.name)
      } else {
        let decoded = try JSONDecoder().decode(UserResponse.self, from: data)
        
        account = Account(id: decoded.user.id, avatar: decoded.user.avatar, name: decoded.user.name)
      }
    } catch {
      print(error)
    }
  }
  
  func addAccount(id: String, token: String) {
    KeychainItem(account: id).wrappedValue = token
    
    DispatchQueue.main.async {
      Preferences.authenticatedAccountIds.append(id)
      Preferences.authenticatedAccountIds = Preferences.authenticatedAccountIds.removingDuplicates()
    }
  }
  
  func deleteAccount(id: String) {
    let keychain = KeychainItem(account: id)
    keychain.wrappedValue = nil
    
    Preferences.authenticatedAccountIds.removeAll { id == $0 }
  }
}
