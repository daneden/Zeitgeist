//
//  UserListRow.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/05/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import SwiftUI

struct UserListRow: View {
  @Environment(\.session) var session
  
  var userId: String
  
  var body: some View {
    if let account = self.session?.fetcherForAccount(id: userId)?.account, let user = account.user {
      HStack {
        VercelUserAvatarView(avatarID: user.avatar).overlay( Group {
          if account.isTeam, let avatar = account.avatar {
            VercelUserAvatarView(avatarID: avatar, size: 16)
          } else {
            Color.red.frame(width: 16, height: 16).cornerRadius(16)
          }
        }.offset(x: 4, y: 4), alignment: .bottomTrailing)
        
        VStack(alignment: .leading) {
          Text(user.name)
          Text(user.email).foregroundColor(.secondary)
        }
      }.padding(.vertical, 8)
      
      Button(action: {
        self.session?.removeAccount(id: user.id)
      }, label: {
        Text("logoutButton")
      }).foregroundColor(.systemRed)
    } else {
      HStack(spacing: 8) {
        ProgressView()
        Text("Loading").foregroundColor(.secondary)
      }
    }
  }
}

struct UserListRow_Previews: PreviewProvider {
    static var previews: some View {
        UserListRow(userId: "")
    }
}
