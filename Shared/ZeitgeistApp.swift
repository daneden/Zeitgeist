//
//  ZeitgesitApp.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

@main
struct ZeitgeistApp: App {
	#if !os(macOS)
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#else
	@NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	#endif

	@State private var accountManager = AccountManager()
	@State private var deepLinkHandler = DeepLinkHandler()

	var body: some Scene {
		WindowGroup {
			ContentView()
				.environment(accountManager)
				.environment(deepLinkHandler)
				.onOpenURL { url in
					deepLinkHandler.pendingDeepLink = deepLinkHandler.parse(url: url)
				}
		}
		.commands {
			DeploymentCommands()
		}

		#if os(macOS)
		Settings {
			SettingsView()
				.environment(accountManager)
				.formStyle(.grouped)
				.frame(maxWidth: 400)
		}
		#endif
	}
}

extension ZeitgeistApp {
	static var appVersion: String {
		Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
	}
	
	static var majorAppVersion: String {
		String(appVersion.first ?? "0")
	}
}
