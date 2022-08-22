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
	#endif

	var body: some Scene {
		WindowGroup {
			ContentView()
				.onAppear {
					if MigrationHelpers.V3.needsMigration {
						Task {
							await MigrationHelpers.V3.migrateAccountIdsToAccounts()
						}
					}
				}
    }
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
