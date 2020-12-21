//
//  VercelUserAvatarView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct VercelUserAvatarView: View {
  @State var size: CGFloat = 32
  var avatarID: String
  
  var body: some View {
    
    RemoteImage(url: "https://vercel.com/api/www/avatar/\(avatarID)?s=\(size * 2)")
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
