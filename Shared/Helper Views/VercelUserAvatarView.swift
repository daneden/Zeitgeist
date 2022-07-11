//
//  VercelUserAvatarView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct VercelUserAvatarView: View {
  var avatarID: String?
  var teamID: String?
  @State var size: CGFloat = 32
  
  private var url: String {
    if let teamID = teamID {
      return "https://vercel.com/api/www/avatar/?teamId=\(teamID)&s=\(size * 2)"
    } else {
      return "https://vercel.com/api/www/avatar/\(avatarID ?? "")?s=\(size * 2)"
    }
  }
  
  var body: some View {
    AsyncImage(url: URL(string: url)) { image in
      image
        .resizable()
        .scaledToFit()
    } placeholder: {
      Image(systemName: "person.crop.circle.fill")
        .resizable()
        .scaledToFit()
        .foregroundColor(.accentColor)
    }
      .blendMode(.normal)
      .frame(width: size, height: size)
      .cornerRadius(size)
      .overlay(
        RoundedRectangle(cornerRadius: size)
          .stroke(Color.primary.opacity(0.1), lineWidth: 1)
      )
  }
}

struct UserAvatar_Previews: PreviewProvider {
  static var previews: some View {
    VercelUserAvatarView(avatarID: "75cce4b03baffd47382c0ca4364f451a87090684")
  }
}
