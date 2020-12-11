//
//  KeyStore.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

let DEFAULT_ACCOUNT = "Token"
// swiftlint:disable:next force_cast
let DEFAULT_GROUP = "\(Bundle.main.infoDictionary!["AppIdentifierPrefix"] as! String)me.daneden.Zeitgeist"

class KeyStore {
  var account: String
  var group: String
  
  init(account: String = DEFAULT_ACCOUNT, group: String = DEFAULT_GROUP) {
    self.account = account
    self.group = group
  }
  
  func store(token: String) {
    guard let data = token.data(using: .utf8) else {
      print("Error encoding token as data")
      return
    }
    
    let addquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword as String,
                                   kSecAttrAccount as String: account,
                                   kSecValueData as String: data,
                                   kSecAttrSynchronizable as String: kCFBooleanTrue!,
                                   kSecAttrAccessGroup as String: group
    ]
    SecItemDelete(addquery as CFDictionary)
    let status: OSStatus = SecItemAdd(addquery as CFDictionary, nil)
    guard status == errSecSuccess else {
      print("Error storing key")
      return
    }
  }
  
  func clear() {
    let addquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword as String,
                                   kSecAttrAccount as String: account,
                                   kSecAttrSynchronizable as String: kCFBooleanTrue!,
                                   kSecAttrAccessGroup as String: group
    ]
    SecItemDelete(addquery as CFDictionary)
  }
  
  func retrieve() -> String? {
    let getquery: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                   kSecAttrAccount as String: account,
                                   kSecReturnData as String: kCFBooleanTrue!,
                                   kSecMatchLimit as String: kSecMatchLimitOne,
                                   kSecAttrSynchronizable as String: kCFBooleanTrue!,
                                   kSecAttrAccessGroup as String: group
    ]
    
    var item: CFTypeRef?
    let status = SecItemCopyMatching(getquery as CFDictionary, &item)
    guard status == errSecSuccess else {
      print("keyStore.retrieve SecItemCopyMatching error \(status)")
      return nil
    }
    
    guard let data = item as? Data? else {
      print("keyStore.retrieve not data")
      return nil
    }
    
    return String(data: data!, encoding: String.Encoding.utf8)
  }
  
}
