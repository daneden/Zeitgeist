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
	/// Start a Live Activity for a deployment using data from the push notification payload
	/// This avoids network requests in background mode where execution time is limited
	static func startActivity(
		deploymentId: VercelDeployment.ID,
		projectId: VercelProject.ID,
		projectName: String,
		commitMessage: String?
	) async {
		guard ActivityAuthorizationInfo().areActivitiesEnabled else {
			logger.warning("Live Activities are not authorized by the system")
			return
		}

		guard userAllowedLiveActivities(for: projectId) else {
			logger.debug("Live Activities not enabled for project \(projectId)")
			return
		}

		// Check if an activity already exists for this deployment
		let existingActivity = Activity<DeploymentAttributes>.activities.first {
			$0.attributes.deploymentId == deploymentId
		}

		if existingActivity != nil {
			logger.debug("Live Activity already exists for deployment \(deploymentId)")
			return
		}

		// Create deployment cause from the commit message, or use manual if not provided
		let deploymentCause: VercelDeployment.DeploymentCause
		if let message = commitMessage {
			deploymentCause = .pushNotification(message: message)
		} else {
			deploymentCause = .manual
		}

		do {
			let attributes = DeploymentAttributes(
				deploymentId: deploymentId,
				deploymentCause: deploymentCause,
				deploymentProject: projectName
			)

			let contentState = DeploymentAttributes.ContentState(
				deploymentState: .building
			)

			let activity = try Activity<DeploymentAttributes>.request(
				attributes: attributes,
				content: ActivityContent<DeploymentAttributes.ContentState>(state: contentState, staleDate: nil),
				pushType: PushType.token
			)

			logger.notice("Started Live Activity for deployment \(deploymentId)")

			// Listen for push token updates and register with server for remote updates
			Task {
				for await pushToken in activity.pushTokenUpdates {
					let tokenString = pushToken.map { String(format: "%02x", $0) }.joined()
					logger.debug("Live Activity push token: \(tokenString)")

					// Register the activity token with the backend for remote updates
					await registerActivityToken(
						activityToken: tokenString,
						deploymentId: deploymentId,
						projectId: projectId
					)
				}
			}
		} catch {
			logger.error("Failed to start Live Activity: \(error.localizedDescription)")
		}
	}

	/// Register Live Activity token with the backend for remote updates
	private static func registerActivityToken(
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

	/// Update an existing Live Activity
	static func updateActivity(for deploymentId: VercelDeployment.ID, state: VercelDeployment.State) async {
		guard let activity = Activity<DeploymentAttributes>.activities.first(where: {
			$0.attributes.deploymentId == deploymentId
		}) else {
			logger.debug("No Live Activity found for deployment \(deploymentId)")
			return
		}

		let contentState = DeploymentAttributes.ContentState(deploymentState: state)

		await activity.update(
			ActivityContent<DeploymentAttributes.ContentState>(state: contentState, staleDate: nil)
		)

		logger.notice("Updated Live Activity for deployment \(deploymentId) to state \(state.rawValue)")

		// End the activity if the deployment reached a terminal state
		if state == .ready || state == .error || state == .cancelled {
			await endActivity(for: deploymentId, finalState: state)
		}
	}

	/// End a Live Activity
	static func endActivity(for deploymentId: VercelDeployment.ID, finalState: VercelDeployment.State) async {
		guard let activity = Activity<DeploymentAttributes>.activities.first(where: {
			$0.attributes.deploymentId == deploymentId
		}) else {
			logger.debug("No Live Activity found to end for deployment \(deploymentId)")
			return
		}

		let contentState = DeploymentAttributes.ContentState(deploymentState: finalState)

		await activity.end(
			ActivityContent<DeploymentAttributes.ContentState>(state: contentState, staleDate: nil),
			dismissalPolicy: ActivityUIDismissalPolicy.default
		)

		logger.notice("Ended Live Activity for deployment \(deploymentId)")
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
