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
  @KeychainItem(account: "Token", accessGroup: DEFAULT_GROUP) private var accessToken
  
  let willChange = PassthroughSubject<(), Never>()
  
  var token: String? {
    get {
      guard let t = accessToken else { return nil }
      return t
    }
    set {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
      accessToken = newValue
    }
  }
  
  static let shared = Session()
}
