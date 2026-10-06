//
//  ProjectsListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 07/08/2022.
//

import SwiftUI

struct ProjectsListRowView: View {
	@AppStorage(Preferences.projectSummaryDisplayOption) var projectSummaryDisplayOption

	/// Stores only the fields the row renders rather than a whole
	/// `VercelProject` (which carries env vars and full deployment arrays),
	/// so unrelated project changes don't invalidate the row and per-row
	/// input comparison stays cheap.
	var name: String
	var timestamp: Date
	var latestDeployment: VercelDeployment?
	var productionDeployment: VercelDeployment?
	var repoSlug: String?
	var provider: GitSVNProvider?

	init(project: VercelProject) {
		name = project.name
		timestamp = project.updated ?? project.created
		latestDeployment = project.latestDeployments?.first
		productionDeployment = project.targets?.production
		repoSlug = project.link?.repoSlug
		provider = project.link?.type
	}

	var deploymentSummarySource: VercelDeployment? {
		switch projectSummaryDisplayOption {
		case .latestDeployment:
			return latestDeployment
		case .productionDeployment:
			return productionDeployment
		}
	}

	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack(alignment: .firstTextBaseline) {
				Text(name)
					.font(.headline)
				Spacer()
				Text(timestamp, style: .relative)
					.foregroundStyle(.secondary)
					.font(.caption)
			}

			if let productionDeploymentCause = deploymentSummarySource?.deploymentCause {
				if case .deployHook = productionDeploymentCause,
				   let icon = productionDeploymentCause.icon
				{
					Text("\(Image(icon)) \(productionDeploymentCause.description)", comment: "The cause of a deployment in the projects list")
						.lineLimit(2)
				} else {
					Text(productionDeploymentCause.description).lineLimit(2)
						.contentTransition(.numericText())
						.animation(.default, value: projectSummaryDisplayOption)
				}
			}

			if let repoSlug,
			   let provider
			{
				Text("\(Image(provider.rawValue)) \(repoSlug)", comment: "Icon and name of a repository for a project in the projects list")
					.font(.footnote)
					.foregroundStyle(.secondary)
			}
		}
		.padding(.vertical, 4)
	}
}

struct ProjectsListRowView_Previews: PreviewProvider {
	static var previews: some View {
		ProjectsListRowView(project: .exampleData)
			.previewLayout(.sizeThatFits)
	}
}
