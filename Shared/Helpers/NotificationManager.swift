//
//  NotificationManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation
import OSLog
import SwiftUI
import UserNotifications

class NotificationManager {
	static let shared = NotificationManager()
	private let notificationCenter = UNUserNotificationCenter.current()

	static func requestAuthorization() async throws -> Bool {
		return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
	}
}

/// The notification settings, read from the store rather than through
/// `@AppStorage`, whose values only update inside views.
struct NotificationPreferences: Codable, Equatable {
	var building: [VercelProject.ID]
	var error: [VercelProject.ID]
	var ready: [VercelProject.ID]
	var productionOnly: [VercelProject.ID]
	var emoji: Bool
	var grouping: NotificationGrouping

	static func current(in store: UserDefaults = Preferences.store) -> NotificationPreferences {
		func projectIds(_ preference: Preferences.AppStorageKVPair<[VercelProject.ID]>) -> [VercelProject.ID] {
			store.string(forKey: preference.key.rawValue).flatMap([VercelProject.ID].init(rawValue:)) ?? preference.value
		}

		return NotificationPreferences(
			building: projectIds(Preferences.deploymentNotificationIds),
			error: projectIds(Preferences.deploymentErrorNotificationIds),
			ready: projectIds(Preferences.deploymentReadyNotificationIds),
			productionOnly: projectIds(Preferences.deploymentNotificationsProductionOnly),
			emoji: store.object(forKey: Preferences.notificationEmoji.key.rawValue) as? Bool
				?? Preferences.notificationEmoji.value,
			grouping: store.string(forKey: Preferences.notificationGrouping.key.rawValue)
				.flatMap(NotificationGrouping.init(rawValue:)) ?? Preferences.notificationGrouping.value
		)
	}

	/// The server applies the same rules (`shouldAlert` in the microsite) to devices that have synced.
	func allows(_ eventType: ZPSEventType,
	            projectId: VercelProject.ID,
	            target: VercelDeployment.Target? = nil) -> Bool
	{
		if productionOnly.contains(projectId), target != .production {
			return false
		}

		switch eventType {
		case .deployment:
			return building.contains(projectId)
		case .deploymentError, .deploymentCanceled:
			return error.contains(projectId)
		case .deploymentReady:
			return ready.contains(projectId)
		default:
			// TODO: Add proper handling for event notifications and migrate to notifications based on project subscriptions
			return true
		}
	}
}

/// Sends the notification settings and signed-in accounts to the server.
///
/// Once the server has them, it sends an alert push for each event the user
/// wants instead of a background push for the app to filter: the system
/// throttles background pushes, keeps only the newest one it holds, and drops
/// them for apps the user force-quit.
@MainActor
final class NotificationSync {
	static let shared = NotificationSync()

	/// The request body, and what the last successful sync sent.
	private struct Snapshot: Codable, Equatable {
		var token: String
		var platform: String
		var accounts: [VercelAccount.ID]
		var preferences: NotificationPreferences

		enum CodingKeys: String, CodingKey {
			case token = "device_id", platform, accounts, preferences
		}
	}

	private struct SyncState: Codable {
		var snapshot: Snapshot
		var date: Date
	}

	private static let logger = Logger(
		subsystem: Bundle.main.bundleIdentifier!,
		category: String(describing: NotificationSync.self)
	)

	private static let endpoint = URL(string: "https://zeitgeist.link/api/notificationPreferences")!

	/// Restores settings the server dropped, such as when APNs reported the
	/// token as lapsed; until then the device would get only legacy pushes,
	/// and a Mac none at all.
	private static let resyncInterval: TimeInterval = 60 * 60 * 24

	private var observers: [NSObjectProtocol] = []
	private var pending: Task<Void, Never>?
	private var pendingSnapshot: Snapshot?

	func start() {
		guard observers.isEmpty else { return }

		#if canImport(UIKit)
			let didBecomeActive = UIApplication.didBecomeActiveNotification
		#elseif canImport(AppKit)
			let didBecomeActive = NSApplication.didBecomeActiveNotification
		#endif

		// Settings, accounts and the device token all live in the store, and
		// the macOS Settings window can change them with no other window open
		for name in [UserDefaults.didChangeNotification, didBecomeActive] {
			observers.append(NotificationCenter.default.addObserver(forName: name, object: nil, queue: .main) { _ in
				MainActor.assumeIsolated {
					NotificationSync.shared.scheduleSync()
				}
			})
		}

		scheduleSync()
	}

	private func scheduleSync() {
		guard let snapshot = currentSnapshot(), snapshot != pendingSnapshot, needsSync(snapshot) else {
			return
		}

		pending?.cancel()
		pendingSnapshot = snapshot
		pending = Task {
			// Toggling several settings in a row sends one request
			try? await Task.sleep(for: .seconds(1))
			guard !Task.isCancelled else { return }

			await sync(snapshot)

			if pendingSnapshot == snapshot {
				pendingSnapshot = nil
			}
		}
	}

	private func currentSnapshot() -> Snapshot? {
		guard let token = Preferences.store.string(forKey: Preferences.Keys.apnsDeviceToken.rawValue),
		      let accounts = signedInAccounts()
		else {
			return nil
		}

		return Snapshot(token: token, platform: platform, accounts: accounts.sorted(), preferences: .current())
	}

	/// Nil if the stored accounts can't be read; syncing an empty list then would
	/// sign the device out of every account's pushes.
	private func signedInAccounts() -> [VercelAccount.ID]? {
		let accounts = UserDefaultsAccountStorage().loadAccounts()
		if accounts.isEmpty,
		   let stored = Preferences.store.string(forKey: Preferences.Keys.authenticatedAccounts.rawValue),
		   stored != "[]"
		{
			return nil
		}
		return accounts.map(\.id)
	}

	private func needsSync(_ snapshot: Snapshot) -> Bool {
		guard let data = Preferences.store.data(forKey: Preferences.Keys.notificationSync.rawValue),
		      let last = try? JSONDecoder().decode(SyncState.self, from: data)
		else {
			return true
		}

		return last.snapshot != snapshot || last.date.timeIntervalSinceNow < -Self.resyncInterval
	}

	private func sync(_ snapshot: Snapshot) async {
		var request = URLRequest(url: Self.endpoint)
		request.httpMethod = "POST"
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")

		do {
			request.httpBody = try JSONEncoder().encode(snapshot)
			let (_, response) = try await URLSession.shared.data(for: request)

			let status = (response as? HTTPURLResponse)?.statusCode ?? 0
			guard (200 ..< 300).contains(status) else {
				Self.logger.error("Notification settings sync failed with status \(status)")
				return
			}

			let state = try JSONEncoder().encode(SyncState(snapshot: snapshot, date: .now))
			Preferences.store.set(state, forKey: Preferences.Keys.notificationSync.rawValue)
			Self.logger.notice("Synced notification settings for \(snapshot.accounts.count) accounts")
		} catch {
			// The next settings change or app activation tries again
			Self.logger.error("Notification settings sync failed: \(error.localizedDescription, privacy: .public)")
		}
	}
}
