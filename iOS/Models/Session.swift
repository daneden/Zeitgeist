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

class Session: ObservableObject {
  static let shared = Session()
  
  @Published var accountId: String? {
    didSet {
      Preferences.store.set(accountId, forKey: "currentAccountId")
    }
  }
  
  @Published var authenticatedAccountIds: [String] {
    didSet {
      Preferences.store.set(authenticatedAccountIds, forKey: "authenticatedAccountIds")
    }
  }
  
  init() {
    if let authenticatedAccountIds = Preferences.store.array(forKey: "authenticatedAccountIds") as? [String] {
      self.authenticatedAccountIds = authenticatedAccountIds
    } else {
      self.authenticatedAccountIds = .init()
    }
    
    if let currentAccountId = Preferences.store.string(forKey: "currentAccountId") {
      do {
        try self.setCurrentAccount(id: currentAccountId)
      } catch {
        print(error.localizedDescription)
      }
    }
  }
  
  func addAccount(id: String, token: String) {
    DispatchQueue.main.async {
      self.accountId = id
    }
    
    KeychainItem(account: id).wrappedValue = token
    
    authenticatedAccountIds.append(id)
    authenticatedAccountIds = authenticatedAccountIds.removingDuplicates()
  }
  
  func setCurrentAccount(id: String) throws {
    guard let _ = KeychainItem(account: id).wrappedValue else {
      throw SessionError.notAuthenticated
    }
    
    self.accountId = id
  }
  
  func deleteAccount(id: String) {
    let keychain = KeychainItem(account: id)
    keychain.wrappedValue = nil
    
    authenticatedAccountIds.removeAll { candidate in
      id == candidate
    }
    
    if authenticatedAccountIds.isEmpty {
      accountId = nil
    }
  }
}
