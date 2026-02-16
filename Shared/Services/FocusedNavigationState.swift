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
/// This behaves similarly to React Context: views set and clear focus as they appear/disappear,
/// while consumers can read the current values from the environment.
@Observable
@MainActor
final class FocusedNavigationState {
	private(set) var project: VercelProject?
	private(set) var deployment: VercelDeployment?

	func setProject(_ project: VercelProject?) {
		self.project = project

		// Deployment focus cannot exist without a project focus.
		if project == nil {
			deployment = nil
		}
	}

	func clearProject(ifMatching projectId: VercelProject.ID?) {
		guard project?.id == projectId else { return }
		project = nil
		deployment = nil
	}

	func setDeployment(_ deployment: VercelDeployment?) {
		self.deployment = deployment
	}

	func clearDeployment(ifMatching deploymentId: VercelDeployment.ID?) {
		guard deployment?.id == deploymentId else { return }
		deployment = nil
	}
}
