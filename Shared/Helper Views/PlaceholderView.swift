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
			Text("No Project Selected")
		case .DeploymentDetail:
			Text("No Deployment Selected")
		case .DeploymentList:
			Text("No Account Selected")
		case .NoDeployments:
			Text("No Deployments To Show")
		case .NoAccounts:
			Text("No Accounts Found")
		case .NoProjects:
			Text("No Projects To Show")
		case .NoEnvVars:
			Text("No Environment Variables for Project")
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
