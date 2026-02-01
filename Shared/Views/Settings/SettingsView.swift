//
//  SettingsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI
import YapKit

fileprivate extension FeedbackConfig {
	static var zeitgeist = FeedbackConfig(apiKey: Secrets.yapKitAPIKey)
}

struct SettingsView: View {
	@Environment(\.dismiss) var dismiss
	@Environment(AccountManager.self) private var accountManager
	@AppStorage(Preferences.deploymentNotificationIds) private var deploymentNotificationIds
	@AppStorage(Preferences.deploymentErrorNotificationIds) private var deploymentErrorNotificationIds
	@AppStorage(Preferences.deploymentReadyNotificationIds) private var deploymentReadyNotificationIds
	@AppStorage(Preferences.deploymentNotificationsProductionOnly) private var deploymentProductionNotificationIds

	@AppStorage(Preferences.notificationEmoji) var notificationEmoji
	@AppStorage(Preferences.notificationGrouping) var notificationGrouping

	@AppStorage(Preferences.authenticationTimeout) var authenticationTimeout
	
	@AppStorage(Preferences.projectSummaryDisplayOption) var projectSummaryDisplayOption
	
	@State private var showFeedbackForm = false

	var body: some View {
		Form {
			Section("Display") {
				Picker(selection: $projectSummaryDisplayOption) {
					ForEach(ProjectSummaryDisplayOption.allCases, id: \.self) { option in
						Text(option.description)
					}
				} label: {
					Text("Project list shows")
				}
			}
			
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
				Button("Submit feedback", systemImage: "ladybug") {
					showFeedbackForm = true
				}
				.feedbackSheet(isPresented: $showFeedbackForm, config: .zeitgeist)
				
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
					accountManager.accounts.forEach { account in
						accountManager.deleteAccount(id: account.id)
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
