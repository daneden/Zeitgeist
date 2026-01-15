//
//  CommitAuthorAttributionView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/01/2026.
//

import SwiftUI

struct CommitAuthorAttributionView: View {
	var commit: DeploymentMeta
	
	var body: some View {
		if let commitAuthorName = commit.commitAuthorName,
			 let commitAuthorAvatarUrl = commit.commitAuthorAvatarUrl {
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
