//
//  NavigationHelpers.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 04/09/2022.
//

import Foundation

/// Navigation destinations for the detail column's NavigationStack.
/// Used with `.navigationDestination(for:)` for type-safe programmatic navigation.
///
/// Note: Only destinations reachable from within the detail NavigationStack belong here.
/// The content column (ProjectDetailView) uses NavigationSplitView's internal navigation,
/// not this type-safe navigation system.
enum DetailDestinationValue: Hashable {
	/// Navigate to deployment logs from DeploymentDetailView
	case deploymentLogs(deployment: VercelDeployment)
}
