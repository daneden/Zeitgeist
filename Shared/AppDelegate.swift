//
//  AppDelegate.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//


import SwiftUI
import OSLog

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

#if DEBUG
	let platform = "ios_sandbox"
#else
	let platform = "ios"
#endif

class AppDelegate: NSObject {
	@AppStorage(Preferences.authenticatedAccounts)
	private var authenticatedAccounts
	
	@AppStorage(Preferences.notificationEmoji) private var notificationEmoji
	@AppStorage(Preferences.notificationGrouping) private var notificationGrouping
	
	private static let logger = Logger(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: AppDelegate.self)
	)
}

#if canImport(UIKit)
extension AppDelegate: UIApplicationDelegate {
	func application(
		_: UIApplication,
		didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		UIApplication.shared.registerForRemoteNotifications()

		UNUserNotificationCenter.current().delegate = self

		return true
	}

	func applicationWillEnterForeground(_: UIApplication) {
		UNUserNotificationCenter.current().removeAllDeliveredNotifications()
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	func application(_: UIApplication,
									 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		registerDeviceTokenWithZPS(deviceToken)
	}
	
	func application(_: UIApplication,
									 didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print(error.localizedDescription)
	}
	
	func application(_: UIApplication,
									 didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async -> UIBackgroundFetchResult {
		return await handleBackgroundNotification(userInfo)
	}
}
#elseif canImport(AppKit)
extension AppDelegate: NSApplicationDelegate {
	func applicationDidFinishLaunching(_ notification: Notification) {
		NSApplication.shared.registerForRemoteNotifications()
		UNUserNotificationCenter.current().delegate = self
	}
	
	func applicationWillBecomeActive(_ notification: Notification) {
		UNUserNotificationCenter.current().removeAllDeliveredNotifications()
	}
}

extension AppDelegate: UNUserNotificationCenterDelegate {
	func application(_ application: NSApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
		print(error)
	}
	
	func application(_ application: NSApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
		registerDeviceTokenWithZPS(deviceToken)
	}
	
	func application(_ application: NSApplication, didReceiveRemoteNotification userInfo: [String : Any]) {
		Task {
			await handleBackgroundNotification(userInfo)
		}
	}
}
#endif

extension AppDelegate {
	func userNotificationCenter(_: UNUserNotificationCenter,
															didReceive response: UNNotificationResponse) async {
		let userInfo = response.notification.request.content.userInfo
		
		guard let deploymentID = userInfo["DEPLOYMENT_ID"] as? String,
					let teamID = userInfo["TEAM_ID"] as? String else { return }
		
		switch response.notification.request.content.categoryIdentifier {
		case ZPSNotificationCategory.deployment.rawValue:
			#if canImport(UIKit)
			await UIApplication.shared.open(URL(string: "zeitgeist://deployment/\(teamID)/\(deploymentID)")!, options: [:])
			#elseif canImport(AppKit)
			// Open deep link on macOS
			#endif
		default:
			Self.logger.warning("Uncaught notification category identifier: \(response.notification.request.content.categoryIdentifier, privacy: .public)")
		}
	}
	
	func registerDeviceTokenWithZPS(_ deviceToken: Data) {
		Self.logger.trace("Registered for remote notifications; registering in Zeitgeist Postal Service (ZPS)")
		
		authenticatedAccounts.forEach { account in
			let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
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
		WidgetCenter.shared.reloadAllTimelines()
		#endif
		
		await DataTaskModifier.postNotification(userInfo)
		
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
						Preferences.accounts.contains(where: { $0.id == accountId }) else {
				return .noData
			}
			
			let target: String? = userInfo["target"] as? String
			
			guard let eventType: ZPSEventType = ZPSEventType(rawValue: userInfo["eventType"] as? String ?? "") else {
				throw ZPSError.EventTypeCastingError(eventType: userInfo["eventType"])
			}
			
			guard NotificationManager.userAllowedNotifications(
				for: eventType,
				with: projectId,
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
			
			if notificationEmoji {
				content.title = "\(eventType.emojiPrefix)\(content.title)"
			}
			
			content.sound = .default
			
			switch notificationGrouping {
			case .account:
				content.threadIdentifier = teamId ?? userId ?? "accountForProject-\(projectId)"
			case .project:
				content.threadIdentifier = projectId
			case .deployment:
				content.threadIdentifier = deploymentId ?? projectId
			}
			
			content.categoryIdentifier = eventType.rawValue
			content.userInfo = [
				"DEPLOYMENT_ID": "\(deploymentId ?? "nil")",
				"TEAM_ID": "\(teamId ?? "-1")",
				"PROJECT_ID": "\(projectId)",
			]
			
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
