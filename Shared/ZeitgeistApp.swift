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

	var body: some Scene {
		WindowGroup {
			ContentView()
				.task {
					if MigrationHelpers.V3.needsMigration {
						await MigrationHelpers.V3.migrateAccountIdsToAccounts()
					}
				}
		}
		
		#if os(macOS)
		Settings {
			SettingsView()
				.formStyle(.grouped)
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
