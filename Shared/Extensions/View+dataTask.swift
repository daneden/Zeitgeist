//
//  View+dataTask.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 16/07/2022.
//

import SwiftUI

struct DataTaskModifier: ViewModifier {
	@EnvironmentObject var session: VercelSession
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
				print("Updating based background notification")
				Task { await action() }
			}
			.onReceive(session.objectWillChange) { _ in
				print("Updating based on change in session")
				if session.isAuthenticated {
					Task { await action() }
				} else {
					print("Skipping dataTask since the session is no longer authenticated")
				}
			}
			.onChange(of: scenePhase) { currentScenePhase in
				if case .active = currentScenePhase {
					print("Updating based on scenePhase")
					Task { await action() }
				}
			}
	}
}

extension View {
	func dataTask(perform action: @escaping () async -> Void) -> some View {
		modifier(DataTaskModifier(action: action))
	}
}

extension DataTaskModifier {
	static func postNotification() {
		NotificationCenter.default.post(name: .ZPSNotification, object: nil)
	}
}
