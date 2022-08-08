//
//  URL.extension.swift
//  ZeitgeistWidgetsExtension
//
//  Created by Daniel Eden on 03/06/2021.
//

import Foundation

enum PageIdentifier: Hashable {
	case account(id: String)
	case deployment(accountId: String, deploymentId: String)
}

extension URL {
	var isDeepLink: Bool {
		return scheme == "zeitgeist"
	}

	var detailPage: PageIdentifier? {
		guard isDeepLink,
		      pathComponents.count > 1
		else {
			return nil
		}

		let accountId = pathComponents[1]
		var deploymentId: String?
		if pathComponents.count > 2 {
			deploymentId = pathComponents[2]
		}

		if let deploymentId = deploymentId {
			return .deployment(accountId: accountId, deploymentId: deploymentId)
		} else {
			return .account(id: accountId)
		}
	}
}

extension URL {
	static var AppStoreURL = URL(string: "https://apps.apple.com/us/app/zeitgeist/id1526052028")!
	static var ReviewURL = URL(string: AppStoreURL.absoluteString.appending("?action=write-review"))!
}
