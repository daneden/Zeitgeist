//
//  VercelUserAvatarView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct VercelUserAvatarView: View {
  var account: VercelAccount?
  
  var avatarID: String? { account?.avatar }
  
  @State var size: CGFloat = 32
  
  private var url: String {
    return "https://vercel.com/api/www/avatar/\(avatarID ?? "")?s=\(size)"
  }
  
  var body: some View {
    AsyncImage(url: URL(string: url), scale: 2) { image in
      image
        .resizable()
        .scaledToFit()
        .clipShape(Circle())
        .overlay(
          Circle()
            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
    } placeholder: {
      Image(systemName: "person.crop.circle.fill")
        .resizable()
        .scaledToFit()
        .foregroundColor(.accentColor)
    }
    .frame(width: size, height: size)
  }
}

struct UserAvatar_Previews: PreviewProvider {
  static var previews: some View {
    VercelUserAvatarView(account: nil)
  }
}
