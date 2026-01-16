//
//  DeepLinkHandler.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 16/01/2026.
//

import Foundation

@Observable
@MainActor
final class DeepLinkHandler {
	enum DeepLink: Equatable {
		case deployment(accountId: String, deploymentId: String, projectId: String?)
	}

	var pendingDeepLink: DeepLink?

	/// Parses a URL into a DeepLink if it matches a known pattern
	/// Supported patterns:
	/// - zeitgeist://deployment/{accountId}/{deploymentId}/{projectId}
	/// - zeitgeist://deployment/{accountId}/{deploymentId} (projectId optional)
	/// - zeitgeist://open/{accountId}/{deploymentId} (legacy widget format)
	func parse(url: URL) -> DeepLink? {
		guard url.scheme == "zeitgeist" else { return nil }

		let pathComponents = url.pathComponents.filter { $0 != "/" }

		guard pathComponents.count >= 2 else { return nil }

		let host = url.host ?? ""

		// URL structure: zeitgeist://deployment/{accountId}/{deploymentId}/{projectId?}
		// or: zeitgeist://open/{accountId}/{deploymentId}
		// Note: The "deployment" or "open" part becomes the host in URL parsing
		if host == "deployment" || host == "open" {
			let accountId = pathComponents[0]
			let deploymentId = pathComponents[1]
			let projectId = pathComponents.count >= 3 ? pathComponents[2] : nil
			return .deployment(accountId: accountId, deploymentId: deploymentId, projectId: projectId)
		}

		return nil
	}
}
