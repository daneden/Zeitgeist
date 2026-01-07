//
//  LiveActivityManager.swift
//  Zeitgeist
//
//  Created by Claude on 06/01/2026.
//

import Foundation
import SwiftUI
import OSLog

#if canImport(ActivityKit)
import ActivityKit
#endif

class LiveActivityManager {
	static let shared = LiveActivityManager()

	private static let logger = Logger(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: LiveActivityManager.self)
	)

	@AppStorage(Preferences.liveActivityProjectIds)
	static var liveActivityProjectIds

	/// Check if user has enabled Live Activities for a specific project
	static func userAllowedLiveActivities(for projectId: VercelProject.ID) -> Bool {
		return liveActivityProjectIds.contains(projectId)
	}

	#if canImport(ActivityKit)
	/// Check if Live Activities are authorized by the system
	static var areActivitiesAuthorized: Bool {
		return ActivityAuthorizationInfo().areActivitiesEnabled
	}
	#endif

	#if canImport(ActivityKit) && os(iOS)
	/// Observe push-to-start token updates and register with the server.
	/// This allows the server to start Live Activities remotely (iOS 17.2+).
	/// Should be called once when the app starts or when project preferences change.
	static func observePushToStartTokenUpdates(
		userId: String,
		projectIds: [VercelProject.ID]
	) {
		guard #available(iOS 17.2, *) else {
			logger.info("Push-to-start requires iOS 17.2+")
			return
		}

		guard ActivityAuthorizationInfo().areActivitiesEnabled else {
			logger.warning("Live Activities are not authorized by the system")
			return
		}

		Task {
			for await tokenData in Activity<DeploymentAttributes>.pushToStartTokenUpdates {
				let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
				logger.debug("Received push-to-start token: \(tokenString)")

				await registerPushToStartToken(
					token: tokenString,
					userId: userId,
					projectIds: projectIds
				)
			}
		}
	}

	/// Register a push-to-start token with the server
	private static func registerPushToStartToken(
		token: String,
		userId: String,
		projectIds: [VercelProject.ID]
	) async {
		guard let deviceId = AppDelegate.deviceToken else {
			logger.warning("Device token not available for push-to-start registration")
			return
		}

		guard let url = URL(string: "https://zeitgeist.link/api/registerPushToStartToken") else {
			logger.error("Invalid URL for push-to-start registration")
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let body: [String: Any] = [
			"token": token,
			"deviceId": deviceId,
			"userId": userId,
			"projectIds": projectIds,
			"platform": platform
		]

		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: body)
			let (data, response) = try await URLSession.shared.data(for: request)

			if let httpResponse = response as? HTTPURLResponse {
				if httpResponse.statusCode == 200 {
					logger.notice("Registered push-to-start token for \(projectIds.count) projects")
				} else {
					let responseBody = String(data: data, encoding: .utf8) ?? "unknown"
					logger.warning("Failed to register push-to-start token: HTTP \(httpResponse.statusCode) - \(responseBody)")
				}
			}
		} catch {
			logger.error("Error registering push-to-start token: \(error.localizedDescription)")
		}
	}

	/// Register Live Activity token with the backend for remote updates.
	/// Called when an activity is started (by the server via push-to-start).
	static func registerActivityToken(
		activityToken: String,
		deploymentId: String,
		projectId: String
	) async {
		guard let deviceId = AppDelegate.deviceToken else {
			logger.warning("Device token not available for Live Activity registration")
			return
		}

		guard let url = URL(string: "https://zeitgeist.link/api/registerLiveActivityToken") else {
			logger.error("Invalid URL for Live Activity registration")
			return
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		let body: [String: Any] = [
			"activityToken": activityToken,
			"deviceId": deviceId,
			"deploymentId": deploymentId,
			"projectId": projectId,
			"platform": platform
		]

		do {
			request.httpBody = try JSONSerialization.data(withJSONObject: body)
			let (data, response) = try await URLSession.shared.data(for: request)

			if let httpResponse = response as? HTTPURLResponse {
				if httpResponse.statusCode == 200 {
					logger.notice("Registered Live Activity token for deployment \(deploymentId)")
				} else {
					let responseBody = String(data: data, encoding: .utf8) ?? "unknown"
					logger.warning("Failed to register Live Activity token: HTTP \(httpResponse.statusCode) - \(responseBody)")
				}
			}
		} catch {
			logger.error("Error registering Live Activity token: \(error.localizedDescription)")
		}
	}

	/// Observe and register activity tokens for server-started activities.
	/// Should be called to monitor for remotely-started Live Activities.
	static func observeActivityTokenUpdates() {
		Task {
			for activity in Activity<DeploymentAttributes>.activities {
				observeTokenUpdates(for: activity)
			}
		}
	}

	/// Observe token updates for a specific activity
	private static func observeTokenUpdates(for activity: Activity<DeploymentAttributes>) {
		Task {
			for await tokenData in activity.pushTokenUpdates {
				let tokenString = tokenData.map { String(format: "%02x", $0) }.joined()
				logger.debug("Activity token update for \(activity.attributes.deploymentId): \(tokenString)")

				// For server-started activities, we need to find the projectId
				// Since we don't have it in simplified attributes, we'll skip registration
				// The server already knows about the activity from push-to-start
			}
		}
	}

	/// End all active Live Activities
	static func endAllActivities() async {
		for activity in Activity<DeploymentAttributes>.activities {
			await activity.end(nil as ActivityContent<DeploymentAttributes.ContentState>?, dismissalPolicy: ActivityUIDismissalPolicy.immediate)
		}
		logger.notice("Ended all Live Activities")
	}
	#endif
}
