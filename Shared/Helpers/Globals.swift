//
//  Globals.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

var APP_VERSION: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

#if os(macOS)
var IS_MACOS: Bool = true
#else
var IS_MACOS: Bool = false
#endif
