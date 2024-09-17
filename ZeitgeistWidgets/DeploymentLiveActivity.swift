//
//  DeploymentLiveActivity.swift
//  ZeitgeistWidgetsExtension
//
//  Created by Daniel Eden on 13/04/2024.
//

import SwiftUI
import WidgetKit
import ActivityKit

struct DeploymentAttributes: ActivityAttributes {
	struct ContentState: Codable & Hashable {
		let deploymentState: VercelDeployment.State
	}
	
	let deploymentId: VercelDeployment.ID
	let deploymentCause: VercelDeployment.DeploymentCause
	let deploymentProject: String
}
