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
}
