//
//  LatestDeploymentEntry.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/05/2021.
//  Updated by Brad Bergeron on 22/11/2023.
//

import Foundation
import WidgetKit

// MARK: - LatestDeploymentEntry

struct LatestDeploymentEntry: TimelineEntry {
	let date = Date()
	var deployment: VercelDeployment?
	var account: WidgetAccount
	var project: WidgetProject?
	var relevance: TimelineEntryRelevance?
}

#if DEBUG

extension LatestDeploymentEntry {
	static var mockNoAccount = LatestDeploymentEntry(
		account: WidgetAccount(identifier: nil, display: "No Account"))

	static var mockExample = LatestDeploymentEntry(
		deployment: VercelProject.exampleData.targets!.production!,
		account: WidgetAccount(identifier: "1", display: "Test Account"),
		project: WidgetProject(identifier: "1", display: "example-project"))
}

#endif
