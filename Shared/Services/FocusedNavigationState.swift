//
//  FocusedNavigationState.swift
//  Zeitgeist
//
//  Created by Codex on 16/02/2026.
//

import Foundation
import Observation

/// Shared app-level navigation context for the currently focused project and deployment.
///
/// Parent navigation state writes focus values, while consumers read them from the environment.
@Observable
@MainActor
final class FocusedNavigationState {
	private(set) var project: VercelProject?
	private(set) var deployment: VercelDeployment?

	func setProject(_ project: VercelProject?) {
		let previousProjectId = self.project?.id
		self.project = project

		// Deployment focus cannot exist without a matching project focus.
		if project == nil || previousProjectId != project?.id {
			deployment = nil
		}
	}

	func setDeployment(_ deployment: VercelDeployment?) {
		self.deployment = deployment
	}
}
