//
//  Array.extension.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

extension Array where Element: Hashable {
  func removingDuplicates() -> [Element] {
    var addedDict = [Element: Bool]()
    
    return filter {
      addedDict.updateValue(true, forKey: $0) == nil
    }
  }
  
  mutating func removeDuplicates() {
    self = self.removingDuplicates()
  }
  
  mutating func toggleElement(_ element: Element, inArray: Bool) {
    if inArray {
      self.append(element)
      self.removeDuplicates()
    } else {
      self.removeAll { $0 == element }
    }
  }
  
  func contains(_ element: Element) -> Bool {
    self.contains { $0 == element }
  }
}

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
