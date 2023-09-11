//
//  PlaceholderView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

enum PlaceholderRole {
	case DeploymentList, DeploymentDetail, NoDeployments, NoAccounts, ProjectDetail, NoProjects, NoEnvVars
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
		}
	}

	var text: Text {
		switch forRole {
		case .ProjectDetail:
			return Text("No Project Selected")
		case .DeploymentDetail:
			return Text("No Deployment Selected")
		case .DeploymentList:
			return Text("No Account Selected")
		case .NoDeployments:
			return Text("No Deployments To Show")
		case .NoAccounts:
			return Text("No Accounts Found")
		case .NoProjects:
			return Text("No Projects To Show")
		case .NoEnvVars:
			return Text("No Environment Variables for Project")
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
