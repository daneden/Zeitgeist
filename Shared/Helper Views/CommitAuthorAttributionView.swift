//
//  CommitAuthorAttributionView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/01/2026.
//

import Rehearsal
import SwiftUI

struct CommitAuthorAttributionView: View {
	/// Stores just the two fields this view renders rather than a whole
	/// `DeploymentMeta`, so unrelated metadata changes don't invalidate it.
	var authorName: String?
	var avatarURL: URL?

	init(commit: DeploymentMeta) {
		self.init(authorName: commit.commitAuthorName, avatarURL: commit.commitAuthorAvatarUrl)
	}

	init(authorName: String?, avatarURL: URL?) {
		self.authorName = authorName
		self.avatarURL = avatarURL
	}

	var body: some View {
		if let commitAuthorName = authorName,
		   let commitAuthorAvatarUrl = avatarURL
		{
			HStack(spacing: 4) {
				AsyncImage(url: commitAuthorAvatarUrl) { image in
					image
						.resizable()
						.frame(maxWidth: 16, maxHeight: 16)
						.avatarMask()
				} placeholder: {
					ProgressView()
						.controlSize(.small)
				}

				Text(commitAuthorName)
			}
		}
	}
}

#Preview {
	Rehearse(CommitAuthorAttributionView.self) { param in
		CommitAuthorAttributionView(
			authorName: param("authorName", default: "Max Mayfield"),
			avatarURL: URL(string: "https://avatars.githubusercontent.com/daneden?s=48")
		)
	}
}
