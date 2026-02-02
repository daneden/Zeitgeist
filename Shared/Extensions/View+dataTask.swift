//
//  View+dataTask.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 16/07/2022.
//

import SwiftUI

struct DataTaskModifier: ViewModifier {
	@Environment(\.session) private var session
	@Environment(\.scenePhase) var scenePhase
	
	let scope: DataTaskModifier.NotificationScope
	let action: () async -> Void

	func body(content: Content) -> some View {
		content
			.task {
				print("Updating from .task modifier")
				await action()
			}
			.refreshable {
				print("Updating due to refresh")
				await action()
			}
			.onReceive(NotificationCenter.default.publisher(for: .ZPSNotification)) { notification in
				print("Updating based on background notification")
				if let scope = notification.object as? DataTaskModifier.NotificationScope {
					Task { await respondToNotification(in: scope) }
				} else {
					Task { await action() }
				}
			}
			.onChange(of: session?.account.id) { oldValue, newValue in
				print("Updating based on change in session account")
				guard let session, session.isAuthenticated else {
					print("Skipping dataTask since the session is no longer authenticated")
					return
				}
				if oldValue != newValue {
					Task { await action() }
				}
			}
			.onChange(of: scenePhase) { _, newValue in
				if case .active = newValue {
					print("Updating based on scenePhase")
					Task { await action() }
				}
			}
	}
	
	func respondToNotification(in scope: NotificationScope) async {
		print("Notification scoped to \(scope)")
		guard self.scope >= scope else {
			print("Scope \(scope) is narrower than \(self.scope), skipping update")
			return
		}
		await action()
	}
}

extension View {
	func zeitgeistDataTask(scope: DataTaskModifier.NotificationScope = .all,
												 perform action: @escaping () async -> Void) -> some View {
		modifier(DataTaskModifier(scope: scope, action: action))
	}
}

extension DataTaskModifier {
	enum NotificationScope: Comparable {
		case all, account, project, deployment
	}
	
	static func postNotification(_ userInfo: [AnyHashable: Any]? = nil, scope: NotificationScope = .all) {
		NotificationCenter.default.post(name: .ZPSNotification, object: scope, userInfo: userInfo)
	}
}
