//
//  Sequence+asyncMethods.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 07/01/2022.
//

import Foundation

extension Sequence {
  func asyncMap<T>(
    _ transform: (Element) async throws -> T
  ) async rethrows -> [T] {
    var values = [T]()
    
    for element in self {
      try await values.append(transform(element))
    }
    
    return values
  }
}

extension Sequence {
  func asyncForEach(
    _ operation: (Element) async throws -> Void
  ) async rethrows {
    for element in self {
      try await operation(element)
    }
  }
}
