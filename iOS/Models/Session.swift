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

typealias AccountIDs = [String]

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
  static let shared = Session()

  @AppStorage("authenticatedAccountIds", store: Preferences.store) var authenticatedAccountIds: AccountIDs = []
  
  var accountId: String? {
    authenticatedAccountIds.first
  }

  init() {
    if let currentAccountId = Preferences.store.string(forKey: "currentAccountId") {
      do {
        try self.setCurrentAccount(id: currentAccountId)
      } catch {
        print(error.localizedDescription)
      }
    }
  }

  func addAccount(id: String, token: String) {
    KeychainItem(account: id).wrappedValue = token

    authenticatedAccountIds.append(id)
    authenticatedAccountIds = authenticatedAccountIds.removingDuplicates()
  }

  func setCurrentAccount(id: String) throws {
    guard let _ = KeychainItem(account: id).wrappedValue else {
      throw SessionError.notAuthenticated
    }
  }

  func deleteAccount(id: String) {
    let keychain = KeychainItem(account: id)
    keychain.wrappedValue = nil

    authenticatedAccountIds.removeAll { candidate in
      id == candidate
    }
  }
}