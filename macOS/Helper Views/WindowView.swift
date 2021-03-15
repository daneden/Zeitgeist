//
//  WindowView.swift
//  macOS
//
//  Created by Daniel Eden on 15/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import SwiftUI

/// A class to handle opening windows for posts when doubling clicking the entry
class WindowViewController<RootView : View>: NSWindowController {
  convenience init(rootView: RootView) {
    let hostingController = NSHostingController(rootView: rootView)
    let window = NSWindow(contentViewController: hostingController)
    window.styleMask = [.closable, .titled]
    
    self.init(window: window)
  }
}
