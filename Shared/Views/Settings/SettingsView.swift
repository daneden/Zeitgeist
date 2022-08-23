//
//  SettingsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SettingsView: View {
	@AppStorage(Preferences.deploymentNotificationIds) private var deploymentNotificationIds
	@AppStorage(Preferences.deploymentErrorNotificationIds) private var deploymentErrorNotificationIds
	@AppStorage(Preferences.deploymentReadyNotificationIds) private var deploymentReadyNotificationIds
	@AppStorage(Preferences.deploymentNotificationsProductionOnly) private var deploymentProductionNotificationIds
	
	@AppStorage(Preferences.notificationEmoji) var notificationEmoji
	@AppStorage(Preferences.notificationGrouping) var notificationGrouping
	
	var githubIssuesURL: URL {
		
		var body = """
		> Please give a detailed description of the issue you’re experiencing or the feedback you’d like to provide.
		> Feel free to attach any relevant screenshots or logs, and please keep the app version and device info in the issue!

		App Version: \(ZeitgeistApp.appVersion)
		"""
		
		#if os(iOS)
		body += """
		Device: \(UIDevice.modelName)
		OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
"""
		#endif
		let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""

		return URL(string: "https://github.com/daneden/zeitgeist/issues/new?body=\(encodedBody)")!
	}

	var body: some View {
		NavigationView {
			Form {
				Section {
					Link(destination: githubIssuesURL) {
						Label("Submit Feedback", systemImage: "ladybug")
					}

					Link(destination: .ReviewURL) {
						Label("Review on App Store", systemImage: "star.fill")
					}
				}

				Section {
					Link(destination: URL(string: "https://zeitgeist.daneden.me/privacy")!) {
						Text("Privacy Policy")
					}

					Link(destination: URL(string: "https://zeitgeist.daneden.me/terms")!) {
						Text("Terms of Use")
					}
				}
				
				Section("Notifications") {
					Toggle(isOn: $notificationEmoji) {
						Text("Show Emoji in notification titles")
					}
					
					Picker(selection: $notificationGrouping) {
						ForEach(NotificationGrouping.allCases, id: \.self) { grouping in
							Text(grouping.description)
						}
					} label: {
						Text("Group notifications by")
					}

					LabelView("Preview") {
						NotificationPreviews(showsEmoji: notificationEmoji)
					}
				}
				
				Section("Danger Zone") {
					Button {
						resetNotifications()
					} label: {
						Label("Reset Notification Settings", systemImage: "bell.slash")
					}.disabled(notificationsResettable)
					
					Button(role: .destructive) {
						Preferences.accounts.forEach { account in
							VercelSession.deleteAccount(id: account.id)
						}
					} label: {
						Label("Delete All Accounts", systemImage: "trash")
					}
				}.symbolRenderingMode(.multicolor)
			}
			.navigationTitle("Settings")
		}
	}
}

extension SettingsView {
	func resetNotifications() {
		deploymentNotificationIds = []
		deploymentReadyNotificationIds = []
		deploymentErrorNotificationIds = []
		deploymentProductionNotificationIds = []
	}
	
	var notificationsResettable: Bool {
		(deploymentNotificationIds + deploymentErrorNotificationIds + deploymentReadyNotificationIds + deploymentProductionNotificationIds).isEmpty
	}
}

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView()
	}
}
