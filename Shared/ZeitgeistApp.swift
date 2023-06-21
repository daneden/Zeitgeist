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
	
	var content: some View {
		ContentView()
			.onAppear {
				if MigrationHelpers.V3.needsMigration {
					Task {
						await MigrationHelpers.V3.migrateAccountIdsToAccounts()
					}
				}
			}
	}

	var body: some Scene {
		#if os(macOS)
		MenuBarExtra {
			content
				.frame(width: 800, height: 600)
		} label: {
			LatestEventMenuBarLabel()
		}
		.menuBarExtraStyle(.window)
		
		Settings {
			SettingsView()
		}
		#else
		WindowGroup {
			content
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
