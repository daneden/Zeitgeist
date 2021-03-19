//
//  Config.swift
//  iOS
//
//  Created by Daniel Eden on 19/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

enum AppConfiguration {
  case Debug
  case TestFlight
  case AppStore
}

struct Config {
  // This is private because the use of 'appConfiguration' is preferred.
  private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
  
  // This can be used to add debug statements.
  static var isDebug: Bool {
    #if DEBUG
    return true
    #else
    return false
    #endif
  }
  
  static var appConfiguration: AppConfiguration {
    if isDebug {
      return .Debug
    } else if isTestFlight {
      return .TestFlight
    } else {
      return .AppStore
    }
  }
}
