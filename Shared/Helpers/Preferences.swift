//
//  Preferences.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//

import Foundation
import SwiftUI

struct Preferences {
	enum Keys: String {
		case authenticatedAccounts,
				 authenticatedAccountIds,
				 lastAppVersionOpened,
		     notificationsEnabled,
		     deploymentNotificationsProductionOnly,
		     deploymentReadyNotificationIds,
		     deploymentErrorNotificationIds,
		     deploymentNotificationIds,
				 notificationGrouping,
				 notificationEmoji
	}

	typealias AppStorageKVPair<T> = (key: Keys, value: T)

	static let notificationsEnabled: AppStorageKVPair<Bool> = (.notificationsEnabled, false)
	static let deploymentNotificationsProductionOnly: AppStorageKVPair<[VercelProject.ID]> = (.deploymentNotificationsProductionOnly, [])
	static let deploymentReadyNotificationIds: AppStorageKVPair<[VercelProject.ID]> = (.deploymentReadyNotificationIds, [])
	static let deploymentErrorNotificationIds: AppStorageKVPair<[VercelProject.ID]> = (.deploymentErrorNotificationIds, [])
	static let deploymentNotificationIds: AppStorageKVPair<[VercelProject.ID]> = (.deploymentNotificationIds, [])
	static let authenticatedAccounts: AppStorageKVPair<[VercelAccount]> = (.authenticatedAccounts, [])
	static let lastAppVersionOpened: AppStorageKVPair<String?> = (.lastAppVersionOpened, nil)
	static let notificationEmoji: AppStorageKVPair<Bool> = (.notificationEmoji, false)
	static let notificationGrouping: AppStorageKVPair<NotificationGrouping> = (.notificationGrouping, .project)
	
	@available(*, deprecated)
	static let authenticatedAccountIds: AppStorageKVPair<[VercelAccount.ID]> = (.authenticatedAccountIds, [])

	@AppStorage(Preferences.authenticatedAccounts)
	static var accounts

	static let store = UserDefaults(suiteName: "group.me.daneden.Zeitgeist")!
}

extension AppStorage {
	init(_ kv: Preferences.AppStorageKVPair<Value>) where Value: RawRepresentable, Value.RawValue == String {
		self.init(wrappedValue: kv.value, kv.key.rawValue, store: Preferences.store)
	}

	init(_ kv: Preferences.AppStorageKVPair<Value>) where Value == Bool {
		self.init(wrappedValue: kv.value, kv.key.rawValue, store: Preferences.store)
	}
	
	init(_ kv: Preferences.AppStorageKVPair<Value>) where Value == String? {
		self.init(kv.key.rawValue, store: Preferences.store)
	}
}

enum NotificationGrouping: String, Codable, RawRepresentable, CaseIterable {
	case account, project, deployment

	
	var description: String {
		switch self {
		case .project:
			return "Project"
		case .deployment:
			return "Deployment"
		case .account:
			return "Account"

		}
	}
}
