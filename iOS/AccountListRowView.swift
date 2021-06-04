//
//  AccountListRowView.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

struct AccountListRowView: View {
  @ScaledMetric var avatarSize: CGFloat = 24
  var accountId: String
  
  var placeholderAccount: Account {
    Account(id: accountId, avatar: accountId, name: accountId)
  }
  
  var body: some View {
    AsyncContentView(
      source: AccountViewModel(accountId: accountId),
      placeholderData: placeholderAccount,
      allowsRetries: false
    ) { account in
      Label(
        title: {
          VStack(alignment: .leading) {
            Text(account.name)
            
            if account.isTeam {
              Text("Team Account")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        },
        icon: {
          VercelUserAvatarView(avatarID: account.avatar, size: avatarSize)
        }
      )
    }
  }
}

struct AccountListRowView_Previews: PreviewProvider {
    static var previews: some View {
      AccountListRowView(accountId: "v9dklkDUzwdLE3GZaVteSbJq")
    }
}
