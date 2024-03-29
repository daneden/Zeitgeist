//
//  NotificationManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation
import SwiftUI
import UserNotifications

class NotificationManager {
	static let shared = NotificationManager()
	private let notificationCenter = UNUserNotificationCenter.current()

	static func requestAuthorization() async throws -> Bool {
		return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
	}

	@AppStorage(Preferences.deploymentNotificationIds)
	static var deploymentNotificationIds
	
	@AppStorage(Preferences.deploymentErrorNotificationIds)
	static var deploymentErrorNotificationIds

	@AppStorage(Preferences.deploymentReadyNotificationIds)
	static var deploymentReadyNotificationIds

	@AppStorage(Preferences.deploymentNotificationsProductionOnly)
	static var deploymentNotificationsProductionOnly

	static func userAllowedNotifications(for eventType: ZPSEventType,
	                                     with projectId: VercelProject.ID,
	                                     target: VercelDeployment.Target? = nil) -> Bool
	{
		if deploymentNotificationsProductionOnly.contains(projectId), target != .production {
			return false
		}

		switch eventType {
		case .deployment:
			return deploymentNotificationIds.contains(projectId)
		case .deploymentError:
			return deploymentErrorNotificationIds.contains(projectId)
		case .deploymentReady:
			return deploymentReadyNotificationIds.contains(projectId)
		default:
			// TODO: Add proper handling for event notifications and migrate to notifications based on project subscriptions
			return true
		}
	}
}
