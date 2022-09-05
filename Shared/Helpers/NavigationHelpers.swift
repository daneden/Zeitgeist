//
//  NavigationHelpers.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 04/09/2022.
//

import Foundation

enum SidebarNavigationValue: Hashable {
	case projects(account: VercelAccount)
	case deployments(account: VercelAccount)
}

enum DetailDestinationValue: Hashable {
	case project(id: VercelProject.ID, account: VercelAccount)
	case deployment(id: VercelDeployment.ID, account: VercelAccount)
}
