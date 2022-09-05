//
//  PlaceholderView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

enum PlaceholderRole {
	case DeploymentList, DeploymentDetail, NoDeployments, NoAccounts, ProjectDetail, NoProjects
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
		case .NoDeployments, .NoProjects:
			return "text.magnifyingglass"
		case .NoAccounts:
			return "person.3.fill"
		}
	}

	var text: String {
		switch forRole {
		case .ProjectDetail:
			return "No Project Selected"
		case .DeploymentDetail:
			return "No Deployment Selected"
		case .DeploymentList:
			return "No Account Selected"
		case .NoDeployments:
			return "No Deployments To Show"
		case .NoAccounts:
			return "No Accounts Found"
		case .NoProjects:
			return "No Projects To Show"
		}
	}

	var body: some View {
		VStack(alignment: alignment, spacing: spacing) {
			Image(systemName: imageName)
				.imageScale(.large)
			Text(text)
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
