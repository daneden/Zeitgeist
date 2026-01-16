//
//  WidgetPushHandler.swift
//  ZeitgeistWidgets
//
//  Created by Claude on 2026-01-16.
//

import Foundation
import OSLog
import WidgetKit

/// Handles WidgetKit push notifications for direct widget updates.
/// This allows the backend to push updates directly to widgets without requiring the main app to process them.
@available(iOS 26, macOS 26, *)
struct ZeitgeistWidgetPushHandler: WidgetPushHandler {
	func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
		let tokenString = pushInfo.token.map { String(format: "%02.2hhx", $0) }.joined()
		
		Self.logger.notice("Widget push token updated: \(tokenString.prefix(16))...")
		
		// Register the widget push token with each authenticated account
		let accounts = accountStorage.loadAccounts()
		
		guard !accounts.isEmpty else {
			Self.logger.warning("No authenticated accounts found for widget push registration")
			return
		}
		
		for account in accounts {
			registerWidgetToken(tokenString, for: account)
		}
	}
	
	private let accountStorage: AccountStorage = UserDefaultsAccountStorage()

	private static let logger = Logger(
		subsystem: "me.daneden.Zeitgeist.ZeitgeistWidgets",
		category: String(describing: ZeitgeistWidgetPushHandler.self)
	)

	/// Registers the widget push token with the backend server.
	private func registerWidgetToken(_ token: String, for account: VercelAccount) {
		#if DEBUG
		let platform = "ios_sandbox"
		#else
		let platform = "ios"
		#endif

		guard let url = URL(string: "https://zeitgeist.link/api/registerWidgetPushToken?user_id=\(account.id)&widget_token=\(token)&platform=\(platform)") else {
			Self.logger.error("Failed to construct widget registration URL")
			return
		}

		let request = URLRequest(url: url)

		URLSession.shared.dataTask(with: request) { data, response, error in
			if let error = error {
				Self.logger.error("Error registering widget token: \(error.localizedDescription)")
				return
			}

			if let httpResponse = response as? HTTPURLResponse {
				if httpResponse.statusCode == 200 {
					Self.logger.notice("Successfully registered widget token for account \(account.id)")
				} else {
					Self.logger.error("Widget token registration failed with status \(httpResponse.statusCode)")
				}
			}
		}.resume()
	}
}
