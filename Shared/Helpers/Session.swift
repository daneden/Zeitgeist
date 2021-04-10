//
//  Session.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

// swiftlint:disable:next force_cast
let DEFAULT_GROUP = "\(Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String)me.daneden.Zeitgeist"

final class Session: ObservableObject {
  static let shared = Session()
  @Published var fetchers = [VercelFetcher]()
  @Published var selectedAccount: String?
  @Published var current: VercelFetcher?
  
  @AppStorage(UDValues.authenticatedAccountIDs) private var authenticatedAccountIDs
  private var _accounts = [String: String]() {
    willSet {
      self.objectWillChange.send()
    }
    
    didSet {
      _accounts.forEach { (id, token) in
        KeychainItem(account: id).wrappedValue = token
      }
    }
  }
  
  var accounts: [String: String] { _accounts }
  
  init() {
    reinit()
  }
  
  private func reinit() {
    let ids = Set(authenticatedAccountIDs)
    _accounts = Dictionary(uniqueKeysWithValues: ids.map({ (id) -> (String, String) in
      guard let token = KeychainItem(account: id).wrappedValue else {
        return ("", "")
      }
      
      return (id, token)
    }).filter { (id, token) in
      return !id.isEmpty && !token.isEmpty
    })
    
    fetchers = _accounts.map { (id, _) in
      let account = VercelAccount(id: id)
      let fetcher = VercelFetcher(account: account, withTimer: true)
      
      return fetcher
    }
    
    current = fetchers.first
    
    debugPrint(_accounts)
    debugPrint(fetchers)
  }
  
  func addAccount(id: String, token: String) {
    DispatchQueue.main.async {
      self._accounts = self.accounts.adding(key: id, value: token)
      self.authenticatedAccountIDs.append(id)
      
      self.reinit()
    }
  }
  
  func removeAccount(id: String) {
    _accounts.removeValue(forKey: id)
    authenticatedAccountIDs.removeAll { (value) -> Bool in
      value == id
    }
  }
  
  func removeAllAccounts() {
    _accounts.removeAll()
    authenticatedAccountIDs.removeAll()
  }
}

struct SessionKey: EnvironmentKey {
  static var defaultValue: Session? {
    return .shared
  }
}

extension EnvironmentValues {
  var session: Session? {
    get {
      self[SessionKey]
    }
    set {
      self[SessionKey] = newValue
    }
  }
}
