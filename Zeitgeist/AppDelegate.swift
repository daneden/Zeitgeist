//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Cocoa
import SwiftUI

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {

  var window: NSWindow!
  var widthConstrained: Bool!

  func applicationDidFinishLaunching(_ aNotification: Notification) {
    // Create the SwiftUI view that provides the window contents.
    let contentView = ContentView()
    widthConstrained = false

    // Create the window and set the content view. 
    window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
      styleMask: [.titled, .closable, .miniaturizable, .resizable],
        backing: .buffered, defer: false)
    window.minSize = NSSize(width: 300, height: 500)
    window.maxSize = NSSize(width: 300, height: 500)
    window.delegate = self
    window.center()
    window.setFrameAutosaveName("Main Window")
    window.title = "Zeitgeist"
    window.contentView = NSHostingView(rootView: contentView)
    window.makeKeyAndOrderFront(nil)
  }
  
  func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
    // We want to prevent horizontal window resizing when not in full screen
    return NSSize(width: self.widthConstrained ? 300 : frameSize.width, height: frameSize.height)
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    // Insert code here to tear down your application
  }

  func windowWillEnterFullScreen(_ notification: Notification) {
    self.widthConstrained = false
  }
  
  func windowWillExitFullScreen(_ notification: Notification) {
    self.widthConstrained = true
  }

}

