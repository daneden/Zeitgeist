//
//  RecentDeploymentsEntry.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//  Updated by Brad Bergeron on 22/11/2023.
//

import Foundation
import WidgetKit

// MARK: - RecentDeploymentsEntry

struct RecentDeploymentsEntry: TimelineEntry {
	let date = Date()
	var deployments: [VercelDeployment]?
	var account: WidgetAccount
	var project: WidgetProject?
	var relevance: TimelineEntryRelevance?
}

#if DEBUG

extension RecentDeploymentsEntry {
	static var mockNoAccount = RecentDeploymentsEntry(
		account: WidgetAccount(identifier: nil, display: "No Account"))

	static var mockExample = RecentDeploymentsEntry(
		deployments: Array(repeating: VercelProject.exampleData.targets!.production!, count: 12),
		account: WidgetAccount(identifier: "1", display: "Test Account"),
		project: WidgetProject(identifier: "1", display: "example-project"))
}

#endif
