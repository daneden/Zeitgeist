//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import OSLog
import SwiftUI

#if canImport(WidgetKit)
	import WidgetKit
#endif
import UserNotifications

#if canImport(UIKit)
	typealias RemoteNotificationResult = UIBackgroundFetchResult
#elseif canImport(AppKit)
	enum RemoteNotificationResult {
		case newData, failed, noData
	}
#endif

// The server picks the APNs host from this, so debug builds name the sandbox
#if os(iOS)
	#if DEBUG
		let platform = "ios_sandbox"
	#else
		let platform = "ios"
	#endif
#else
	#if DEBUG
		let platform = "macos_sandbox"
	#else
		let platform = "macos"
	#endif
#endif

class AppDelegate: NSObject {
	private let accountStorage: AccountStorage = UserDefaultsAccountStorage()

	private static let logger = Logger(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: AppDelegate.self)
	)

	/// Authenticated accounts loaded from storage
	private var authenticatedAccounts: [VercelAccount] {
		accountStorage.loadAccounts()
	}
}

#if canImport(UIKit)
	extension AppDelegate: UIApplicationDelegate {
		func application(
			_: UIApplication,
			didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
		) -> Bool {
			UIApplication.shared.registerForRemoteNotifications()

			UNUserNotificationCenter.current().delegate = self

			NotificationSync.shared.start()

			return true
		}
	}

	extension AppDelegate: UNUserNotificationCenterDelegate {
		func application(_: UIApplication,
		                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
		{
			registerDeviceTokenWithZPS(deviceToken)
		}

		func application(_: UIApplication,
		                 didFailToRegisterForRemoteNotificationsWithError error: Error)
		{
			print(error.localizedDescription)
		}

		func application(_: UIApplication,
		                 didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult
		{
			return await handleBackgroundNotification(userInfo)
		}
	}

#elseif canImport(AppKit)
	extension AppDelegate: NSApplicationDelegate {
		func applicationWillFinishLaunching(_: Notification) {
			// Must be set before launch finishes, or a tap that launches the app is lost
			UNUserNotificationCenter.current().delegate = self
		}

		func applicationDidFinishLaunching(_: Notification) {
			NSApplication.shared.registerForRemoteNotifications()
			NotificationSync.shared.start()
		}

		func applicationWillBecomeActive(_: Notification) {
			UNUserNotificationCenter.current().removeAllDeliveredNotifications()
		}
	}

	extension AppDelegate: UNUserNotificationCenterDelegate {
		func application(_: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
			print(error)
		}

		func application(_: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
			registerDeviceTokenWithZPS(deviceToken)
		}

		func application(_: NSApplication, didReceiveRemoteNotification userInfo: [String: Any]) {
			Task {
				await handleBackgroundNotification(userInfo)
			}
		}
	}
#endif

extension AppDelegate {
	@MainActor
	func userNotificationCenter(_: UNUserNotificationCenter,
	                            didReceive response: UNNotificationResponse) async
	{
		let userInfo = response.notification.request.content.userInfo
		/// Local notifications use the uppercase keys; alert pushes from the server use the payload's own
		func value(_ keys: String...) -> String? {
			keys.lazy.compactMap { userInfo[$0] as? String }.first
		}

		// Older builds gave each event type its own category, so route on the payload instead
		guard let deploymentID = value("DEPLOYMENT_ID", "deploymentId") else {
			Self.logger.warning("Uncaught notification category identifier: \(response.notification.request.content.categoryIdentifier, privacy: .public)")
			return
		}

		guard let accountID = value("TEAM_ID", "teamId", "USER_ID", "userId") else {
			Self.logger.warning("Deployment notification missing an account ID")
			return
		}

		let projectID = value("PROJECT_ID", "projectId")
		// Include projectId in URL for parallel fetching optimization
		let projectPath = projectID.map { "/\($0)" } ?? ""
		guard let deepLinkURL = URL(string: "zeitgeist://deployment/\(accountID)/\(deploymentID)\(projectPath)") else {
			Self.logger.error("Failed to construct deep link URL for deployment \(deploymentID, privacy: .public)")
			return
		}
		#if canImport(UIKit)
			await UIApplication.shared.open(deepLinkURL, options: [:])
		#elseif canImport(AppKit)
			NSWorkspace.shared.open(deepLinkURL)
		#endif
	}

	func registerDeviceTokenWithZPS(_ deviceToken: Data) {
		Self.logger.trace("Registered for remote notifications; registering in Zeitgeist Postal Service (ZPS)")

		let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
		// NotificationSync sends it to the server with the notification settings
		Preferences.store.set(token, forKey: Preferences.Keys.apnsDeviceToken.rawValue)

		for account in authenticatedAccounts {
			let url = URL(string: "https://zeitgeist.link/api/registerPushNotifications?user_id=\(account.id)&device_id=\(token)&platform=\(platform)")!
			let request = URLRequest(url: url)

			URLSession.shared.dataTask(with: request) { data, _, error in
				if let error = error {
					Self.logger.error("Error registering device ID to ZPS: \(error, privacy: .auto)")
				}

				if data != nil {
					Self.logger.notice("Successfully registered device ID \(token) to ZPS")
				}
			}.resume()
		}
	}

	@discardableResult
	func handleBackgroundNotification(_ userInfo: [AnyHashable: Any]) async -> RemoteNotificationResult {
		Self.logger.trace("Received remote notification")

		#if canImport(WidgetKit)
			if #unavailable(iOS 26, macOS 26) {
				WidgetCenter.shared.reloadAllTimelines()
			}
		#endif

		await DataTaskModifier.postNotification(userInfo)

		// The server already chose whether to alert: the system shows the alert, if any
		if userInfo["zps"] != nil || (userInfo["aps"] as? [AnyHashable: Any])?["alert"] != nil {
			return .newData
		}

		do {
			let title = userInfo["title"] as? String
			guard let body = userInfo["body"] as? String else {
				throw ZPSError.FieldCastingError(field: userInfo["body"])
			}

			guard let projectId = userInfo["projectId"] as? String else {
				throw ZPSError.FieldCastingError(field: userInfo["projectId"])
			}

			let deploymentId: String? = userInfo["deploymentId"] as? String
			let teamId: String? = userInfo["teamId"] as? String
			let userId: String? = userInfo["userId"] as? String

			guard let accountId = teamId ?? userId,
			      authenticatedAccounts.contains(where: { $0.id == accountId })
			else {
				return .noData
			}

			let target: String? = userInfo["target"] as? String

			guard let eventType = ZPSEventType(rawValue: userInfo["eventType"] as? String ?? "") else {
				throw ZPSError.EventTypeCastingError(eventType: userInfo["eventType"])
			}

			let preferences = NotificationPreferences.current()

			guard preferences.allows(
				eventType,
				projectId: projectId,
				target: VercelDeployment.Target(rawValue: target ?? "")
			) else {
				Self.logger.notice("Notification suppressed due to user preferences")
				return .newData
			}

			let content = UNMutableNotificationContent()

			if let title = title {
				content.title = title
				content.body = body
			} else {
				content.title = body
			}

			if preferences.emoji {
				content.title = "\(eventType.emojiPrefix)\(content.title)"
			}

			content.sound = .default

			switch preferences.grouping {
			case .account:
				content.threadIdentifier = teamId ?? userId ?? "accountForProject-\(projectId)"
			case .project:
				content.threadIdentifier = projectId
			case .deployment:
				content.threadIdentifier = deploymentId ?? projectId
			}

			content.categoryIdentifier = eventType.associatedState == nil
				? ZPSNotificationCategory.project.rawValue
				: ZPSNotificationCategory.deployment.rawValue
			var notificationUserInfo: [String: String] = [
				"PROJECT_ID": projectId,
			]
			if let deploymentId {
				notificationUserInfo["DEPLOYMENT_ID"] = deploymentId
			}
			if let teamId {
				notificationUserInfo["TEAM_ID"] = teamId
			}
			if let userId {
				notificationUserInfo["USER_ID"] = userId
			}
			content.userInfo = notificationUserInfo

			let notificationID = "\(content.threadIdentifier)-\(eventType.rawValue)"

			let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: nil)
			Self.logger.notice("Pushing notification with ID \(notificationID)")
			try await UNUserNotificationCenter.current().add(request)

			return .newData
		} catch {
			switch error {
			case let ZPSError.FieldCastingError(field):
				Self.logger.error("Notification failed with field casting error: \(field.debugDescription, privacy: .public)")
			case let ZPSError.EventTypeCastingError(eventType):
				Self.logger.error("Notification failed with event type casting error: \(eventType.debugDescription)")
			default:
				Self.logger.error("Unknown error occured when handling background notification")
			}

			Self.logger.error("Error details: \(error.localizedDescription, privacy: .public)")

			return .failed
		}
	}
}
