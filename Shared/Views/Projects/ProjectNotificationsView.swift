//
//  ProjectNotificationsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 19/07/2022.
//

import SwiftUI

#if canImport(ActivityKit)
import ActivityKit
#endif

struct ProjectNotificationsView: View {
	@Environment(\.dismiss) var dismiss

	var project: VercelProject

	// Assume notifications have been permitted
	@State private var notificationsPermitted = true

	#if canImport(ActivityKit)
	// Track Live Activities permission status
	@State private var liveActivitiesPermitted = ActivityAuthorizationInfo().areActivitiesEnabled
	#endif

	@AppStorage(Preferences.deploymentNotificationIds)
	private var deploymentNotificationIds

	@AppStorage(Preferences.deploymentErrorNotificationIds)
	private var deploymentErrorNotificationIds

	@AppStorage(Preferences.deploymentReadyNotificationIds)
	private var deploymentReadyNotificationIds

	@AppStorage(Preferences.deploymentNotificationsProductionOnly)
	private var deploymentNotificationsProductionOnly

	@AppStorage(Preferences.liveActivityProjectIds)
	private var liveActivityProjectIds

	var body: some View {
		let allowDeploymentNotifications = Binding {
			deploymentNotificationIds.contains { $0 == project.id }
		} set: { deploymentNotificationIds.toggleElement(project.id, inArray: $0) }

		let allowDeploymentErrorNotifications = Binding {
			deploymentErrorNotificationIds.contains { $0 == project.id }
		} set: { deploymentErrorNotificationIds.toggleElement(project.id, inArray: $0) }

		let allowDeploymentReadyNotifications = Binding {
			deploymentReadyNotificationIds.contains { $0 == project.id }
		} set: { deploymentReadyNotificationIds.toggleElement(project.id, inArray: $0) }

		let productionNotificationsOnly = Binding {
			deploymentNotificationsProductionOnly.contains { $0 == project.id }
		} set: { deploymentNotificationsProductionOnly.toggleElement(project.id, inArray: $0) }

		let allowLiveActivities = Binding {
			liveActivityProjectIds.contains { $0 == project.id }
		} set: { liveActivityProjectIds.toggleElement(project.id, inArray: $0) }

		return Form {
			if !notificationsPermitted {
				Section("Notification permissions required") {
					Text("Go to the Settings app to enable notifications for Zeitgeist")
					#if os(iOS)
					if let url = URL(string: UIApplication.openSettingsURLString),
						 UIApplication.shared.canOpenURL(url) {
						Link(destination: url) {
							Text("Open Settings")
						}
					}
					#endif
				}
			}

			#if canImport(ActivityKit)
			Section {
				Toggle(isOn: allowLiveActivities) {
					Label("Live Activities", systemImage: "bell.badge.fill")
				}

				if !liveActivitiesPermitted && liveActivityProjectIds.contains(project.id) {
					Label {
						Text("Live Activities are disabled in system settings")
					} icon: {
						Image(systemName: "exclamationmark.triangle.fill")
							.foregroundStyle(.yellow)
					}
					.font(.footnote)

					#if os(iOS)
					if let url = URL(string: UIApplication.openSettingsURLString),
						 UIApplication.shared.canOpenURL(url) {
						Link(destination: url) {
							Label("Open Settings", systemImage: "gear")
						}
					}
					#endif
				}
			} header: {
				Text("Live Activities")
			} footer: {
				Text("Show live build status on your Lock Screen and Dynamic Island while deployments are in progress.")
			}
			#endif

			Section {
				Toggle(isOn: productionNotificationsOnly) {
					Label("Production only", systemImage: "theatermasks.fill")
				}
			} footer: {
				Text("When enabled, Zeitgeist will only send the notification types selected below for deployments targeting a production environment.")
			}

			Section {
				Toggle(isOn: allowDeploymentNotifications) {
					DeploymentStateIndicator(state: .building)
				}

				Toggle(isOn: allowDeploymentErrorNotifications) {
					DeploymentStateIndicator(state: .error)
				}

				Toggle(isOn: allowDeploymentReadyNotifications) {
					DeploymentStateIndicator(state: .ready)
				}
			}
		}
		.toolbar {
			Button {
				dismiss()
			} label: {
				Label("Dismiss", systemImage: "xmark")
			}
		}
		.navigationTitle(Text("Notifications for \(project.name)"))
		#if os(iOS)
		.navigationBarTitleDisplayMode(.inline)
		#endif
		.onAppear {
			if notificationsChanged {
				requestAndUpdateNotificationPermittedStatus()
			}
			#if canImport(ActivityKit)
			updateLiveActivitiesPermittedStatus()
			#endif
		}
		.onChange(of: overallNotificationSettings) { _, _ in
			requestAndUpdateNotificationPermittedStatus()
		}
		#if canImport(ActivityKit)
		.onChange(of: liveActivityProjectIds) { _, _ in
			updateLiveActivitiesPermittedStatus()
		}
		#endif
	}

	#if canImport(ActivityKit)
	func updateLiveActivitiesPermittedStatus() {
		liveActivitiesPermitted = ActivityAuthorizationInfo().areActivitiesEnabled
	}
	#endif
	
	func requestAndUpdateNotificationPermittedStatus() {
		Task {
			if let auth = try? await NotificationManager.requestAuthorization() {
				notificationsPermitted = auth
			} else {
				notificationsPermitted = false
			}
		}
	}
}

extension ProjectNotificationsView {
	private var notificationsChanged: Bool {
		!overallNotificationSettings.isEmpty
	}
	
	private var overallNotificationSettings: [String] {
		(deploymentNotificationIds + deploymentReadyNotificationIds + deploymentErrorNotificationIds + deploymentNotificationsProductionOnly)
	}
}
