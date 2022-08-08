//
//  AppDelegate.swift
//  Zeitgeist (macOS)
//
//  Created by Daniel Eden on 08/01/2022.
//

import AppKit
import Foundation
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
	var statusBar: NSStatusBar!
	var statusBarItem: NSStatusItem!

	func applicationDidFinishLaunching(_: Notification) {
		// Create the status item
		statusBar = NSStatusBar.system
		statusBarItem = statusBar.statusItem(withLength: NSStatusItem.variableLength)

		if let button = statusBarItem.button {
			button.image = NSImage(named: "zeitgeist-menu-bar")
			button.action = #selector(revealApplication(_:))
		}
	}

	@objc func revealApplication(_ sender: Any?) {
		let application = NSApplication.shared

		let swiftUIWindows = application.windows.filter { $0.description.contains("SwiftUI") }

		application.activate(ignoringOtherApps: true)

		if swiftUIWindows.isEmpty {
			EnvironmentValues().openURL(URL(string: "zeitgeist://main")!)
		} else {
			swiftUIWindows.first?.makeKeyAndOrderFront(sender)
		}
	}
}
