//
//  PlaceholderView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

enum PlaceholderRole {
	case DeploymentList, DeploymentDetail, NoDeployments, NoAccounts, ProjectDetail, NoProjects, NoEnvVars, AuthError
}

struct PlaceholderView: View {
	@ScaledMetric var spacing: CGFloat = 4
	var forRole: PlaceholderRole
	var alignment: HorizontalAlignment = .center

	var imageName: String {
		switch forRole {
		case .DeploymentDetail, .ProjectDetail:
			return "doc.text.magnifyingglass"
		case .DeploymentList:
			return "person.2.fill"
		case .NoDeployments, .NoProjects, .NoEnvVars:
			return "text.magnifyingglass"
		case .NoAccounts:
			return "person.3.fill"
		case .AuthError:
			return "person.crop.circle.badge.exclamationmark"
		}
	}

	@ViewBuilder
	var text: some View {
		switch forRole {
		case .ProjectDetail:
			Text("No project selected")
		case .DeploymentDetail:
			Text("No deployment selected")
		case .DeploymentList:
			Text("No account selected")
		case .NoDeployments:
			Text("No deployments to show")
		case .NoAccounts:
			Text("No accounts found")
		case .NoProjects:
			Text("No projects to show")
		case .NoEnvVars:
			Text("No environment variables for project")
		case .AuthError:
			VStack {
				Text("Error authenticating account")
					.font(.headline)
				Text("The selected account has not been authorised on this device. You can try signing out and signing in again.")
				SignOutButton()
			}
		}
	}

	var body: some View {
		VStack(alignment: alignment, spacing: spacing) {
			Image(systemName: imageName)
				.imageScale(.large)
			text
		}
		.multilineTextAlignment(alignment == .leading ? .leading : .center)
		.foregroundColor(.secondary)
	}
}

struct PlaceholderView_Previews: PreviewProvider {
	static var previews: some View {
		PlaceholderView(forRole: .DeploymentDetail)
	}
}
