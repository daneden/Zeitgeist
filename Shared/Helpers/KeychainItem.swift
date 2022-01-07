//
//  KeychainItem.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//  swiftlint:disable all

import Foundation
import Security

private func throwIfNotZero(_ status: OSStatus) throws {
  guard status != 0 else { return }
  throw KeychainError.keychainError(status: status)
}

public enum KeychainError: Error {
  case invalidData
  case keychainError(status: OSStatus)
}

extension Dictionary {
  func adding(key: Key, value: Value) -> Dictionary {
    var copy = self
    copy[key] = value
    return copy
  }
}

@propertyWrapper
final public class KeychainItem {
  private let account: String
  private let accessGroup: String?
  
  public init(account: String) {
    self.account = account
    self.accessGroup = nil
  }
  
  public init(account: String, accessGroup: String) {
    self.account = account
    self.accessGroup = accessGroup
  }
  
  private var baseDictionary: [String:AnyObject] {
    let base = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrAccount as String: account as AnyObject,
      kSecAttrSynchronizable as String: kCFBooleanTrue!
    ]
    
    return accessGroup == nil
      ? base
      : base.adding(key: kSecAttrAccessGroup as String, value: accessGroup as AnyObject)
  }
  
  private var query: [String:AnyObject] {
    return baseDictionary.adding(key: kSecMatchLimit as String, value: kSecMatchLimitOne)
  }
  
  public var wrappedValue: String? {
    get {
      try? read()
    }
    set {
      if let v = newValue {
        if let _ = try? read() {
          try! update(v)
        } else {
          try! add(v)
        }
      } else {
        try? delete()
      }
    }
  }
  
  private func delete() throws {
    // SecItemDelete seems to fail with errSecItemNotFound if the item does not exist in the keychain. Is this expected behavior?
    let status = SecItemDelete(baseDictionary as CFDictionary)
    guard status != errSecItemNotFound else { return }
    try throwIfNotZero(status)
  }
  
  private func read() throws -> String? {
    let query = self.query.adding(key: kSecReturnData as String, value: true as AnyObject)
    var result: AnyObject? = nil
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    guard status != errSecItemNotFound else { return nil }
    try throwIfNotZero(status)
    guard let data = result as? Data, let string = String(data: data, encoding: .utf8) else {
      throw KeychainError.invalidData
    }
    return string
  }
  
  private func update(_ secret: String) throws {
    let dictionary: [String:AnyObject] = [
      kSecValueData as String: secret.data(using: String.Encoding.utf8)! as AnyObject
    ]
    try throwIfNotZero(SecItemUpdate(baseDictionary as CFDictionary, dictionary as CFDictionary))
  }
  
  private func add(_ secret: String) throws {
    let dictionary = baseDictionary.adding(key: kSecValueData as String, value: secret.data(using: .utf8)! as AnyObject)
    try throwIfNotZero(SecItemAdd(dictionary as CFDictionary, nil))
  }
}
