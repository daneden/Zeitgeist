//
//  Sequence.swift
//  iOS
//
//  Created by Daniel Eden on 19/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

extension Sequence where Iterator.Element: Hashable {
  func unique() -> [Iterator.Element] {
    var seen: Set<Iterator.Element> = []
    return filter { seen.insert($0).inserted }
  }
}
