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
			.onReceive(NotificationCenter.default.publisher(for: .ZPSNotification)) { _ in
				print("Updating based on background notification")
				Task { await action() }
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
}

extension View {
	func zeitgeistDataTask(perform action: @escaping () async -> Void) -> some View {
		modifier(DataTaskModifier(action: action))
	}
}

extension DataTaskModifier {
	static func postNotification(_ userInfo: [AnyHashable: Any]? = nil) {
		NotificationCenter.default.post(name: .ZPSNotification, object: nil, userInfo: userInfo)
	}
}
