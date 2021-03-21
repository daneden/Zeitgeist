//
//  AppStorage.extension.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 20/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import SwiftUI

extension AppStorage {
  init(_ kv: UDValuePair<Value>) where Value == String {
    self.init(wrappedValue: kv.value, kv.key, store: UD_STORE)
  }
  
  init(_ kv: UDValuePair<Value>) where Value == Bool {
    self.init(wrappedValue: kv.value, kv.key, store: UD_STORE)
  }
  
  init(_ kv: UDValuePair<Value>) where Value == TimeInterval {
    self.init(wrappedValue: kv.value, kv.key, store: UD_STORE)
  }
}
