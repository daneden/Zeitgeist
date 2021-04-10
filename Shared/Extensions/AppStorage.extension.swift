//
//  AppStorage.extension.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 20/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import SwiftUI

typealias UDValuePair<T> = (key: String, value: T)

extension AppStorage {
  init(_ kv: UDValuePair<Value>) where Value == String {
    self.init(wrappedValue: kv.value, kv.key, store: UD_STORE)
  }
  
  init(_ kv: UDValuePair<Value>) where Value == [String] {
    self.init(wrappedValue: kv.value, kv.key, store: UD_STORE)
  }
  
  init(_ kv: UDValuePair<Value>) where Value == Bool {
    self.init(wrappedValue: kv.value, kv.key, store: UD_STORE)
  }
  
  init(_ kv: UDValuePair<Value>) where Value == TimeInterval {
    self.init(wrappedValue: kv.value, kv.key, store: UD_STORE)
  }
}

// Allow Arrays to be used with AppStorage via RawRepresentable conformance
extension Array: RawRepresentable where Element: Codable {
  public init?(rawValue: String) {
    guard let data = rawValue.data(using: .utf8),
          let result = try? JSONDecoder().decode([Element].self, from: data)
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
