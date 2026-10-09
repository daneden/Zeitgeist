//
//  VercelUserAvatarView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct VercelUserAvatarView: View {
	/// Takes just the avatar identifier rather than a whole `VercelAccount`,
	/// so unrelated account changes don't invalidate the avatar.
	var avatarID: String?

	var size: CGFloat = 32

	init(account: VercelAccount?, size: CGFloat = 32) {
		self.init(avatarID: account?.avatar, size: size)
	}

	init(avatarID: String?, size: CGFloat = 32) {
		self.avatarID = avatarID
		self.size = size
	}

	private var url: String {
		return "https://vercel.com/api/www/avatar/\(avatarID ?? "")?s=\(size)"
	}

	var body: some View {
		AsyncImage(url: URL(string: url), scale: 2) { image in
			image
				.resizable()
				.scaledToFit()
				.avatarMask()
		} placeholder: {
			Image(systemName: "person.crop.circle.fill")
				.resizable()
				.scaledToFit()
				.foregroundStyle(.tint)
		}
		.frame(width: size, height: size)
	}
}

struct UserAvatar_Previews: PreviewProvider {
	static var previews: some View {
		VercelUserAvatarView(account: nil)
	}
}
