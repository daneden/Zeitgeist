//
//  URL.extension.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation

extension URL {
  static let appScheme = "zeitgeist"
  static let appDeploymentPath = "deployment"
  
  var isDeeplink: Bool {
    return scheme == "zeitgeist" // matches my-url-scheme://<rest-of-the-url>
  }
}
