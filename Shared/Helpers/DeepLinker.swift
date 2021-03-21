//
//  DeepLinker.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

class Deeplinker {
  enum Deeplink: Equatable {
    case home
    case deployment(teamId: String, deploymentId: String)
  }
  
  func manage(url: URL) -> Deeplink? {
    guard url.scheme == URL.appScheme else { return nil }
    guard url.host == URL.appDeploymentPath else { return .home }
    let components = url.pathComponents
    
    guard components.count > 2 else { return nil }
    
    return .deployment(teamId: components[1], deploymentId: components[2])
  }
}

struct DeeplinkKey: EnvironmentKey {
  static var defaultValue: Deeplinker.Deeplink? {
    return nil
  }
}

extension EnvironmentValues {
  var deeplink: Deeplinker.Deeplink? {
    get {
      self[DeeplinkKey]
    }
    set {
      self[DeeplinkKey] = newValue
    }
  }
}
