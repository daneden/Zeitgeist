//
//  SettingsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SettingsView: View {
	@Environment(\.dismiss) var dismiss
	@AppStorage(Preferences.deploymentNotificationIds) private var deploymentNotificationIds
	@AppStorage(Preferences.deploymentErrorNotificationIds) private var deploymentErrorNotificationIds
	@AppStorage(Preferences.deploymentReadyNotificationIds) private var deploymentReadyNotificationIds
	@AppStorage(Preferences.deploymentNotificationsProductionOnly) private var deploymentProductionNotificationIds
	
	@AppStorage(Preferences.notificationEmoji) var notificationEmoji
	@AppStorage(Preferences.notificationGrouping) var notificationGrouping
	
	@AppStorage(Preferences.authenticationTimeout) var authenticationTimeout
	
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
		Form {
			Section {
				Picker(selection: $notificationGrouping) {
					ForEach(NotificationGrouping.allCases, id: \.self) { grouping in
						Text(grouping.description)
					}
				} label: {
					Text("Group notifications by")
				}
				
				Toggle(isOn: $notificationEmoji) {
					Text("Show Emoji in notification titles")
				}
			} header: {
				Text("Notifications")
			} footer: {
				Text("Optionally display emoji to quickly denote different build statuses: ⏱ Build Started, ✅ Deployed, and 🛑 Build Failed")
			}
			
			Section {
				Picker(selection: $authenticationTimeout) {
					ForEach(timeoutPresets, id: \.self) { preset in
						Text(Duration.seconds(preset).formatted(.units()))
					}
					
					Text("Never").tag(TimeInterval.infinity)
				} label: {
					Text("Auto-lock after")
				}
			} header: {
				Text("Authentication")
			} footer: {
				Text("Authentication is used to protect sensitive information such as environment variables")
			}
			
			Section {
				Link(destination: githubIssuesURL) {
					Label("Submit feedback", systemImage: "ladybug")
				}
				
				Link(destination: .ReviewURL) {
					Label("Review on the App Store", systemImage: "star.fill")
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
			
			Section("Danger Zone") {
				Button {
					resetNotifications()
				} label: {
					Label("Reset notification settings", systemImage: "bell.slash")
				}.disabled(notificationsResettable)
				
				Button(role: .destructive) {
					Preferences.accounts.forEach { account in
						VercelSession.deleteAccount(id: account.id)
					}
					dismiss()
				} label: {
					Label("Sign out of all accounts", systemImage: "person.badge.minus")
				}
			}.symbolRenderingMode(.multicolor)
		}
		.navigationTitle(Text("Settings"))
		#if os(iOS)
		.toolbar {
			BackportCloseButton {
				dismiss()
			}
		}
		#endif
		
	}
}

extension SettingsView {
	func resetNotifications() {
		DispatchQueue.main.async {
			notificationEmoji = false
			deploymentNotificationIds.removeAll()
			deploymentReadyNotificationIds.removeAll()
			deploymentErrorNotificationIds.removeAll()
			deploymentProductionNotificationIds.removeAll()
		}
	}
	
	var notificationsResettable: Bool {
		(deploymentNotificationIds + deploymentErrorNotificationIds + deploymentReadyNotificationIds + deploymentProductionNotificationIds).isEmpty
	}
}

fileprivate let timeoutPresets: Array<TimeInterval> = [
	60 * 1,
	60 * 5,
	60 * 10,
	60 * 15,
	60 * 30,
	60 * 60
]

struct SettingsView_Previews: PreviewProvider {
	static var previews: some View {
		SettingsView()
	}
}
