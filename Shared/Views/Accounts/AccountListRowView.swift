//
//  AccountListRowView.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

struct AccountListRowView: View {
  #if os(macOS)
  @ScaledMetric var avatarSize: CGFloat = 16
  #else
  @ScaledMetric var avatarSize: CGFloat = 24
  #endif
  var accountId: Account.ID
  @EnvironmentObject var api: VercelAPI
  @Binding var selection: String?
  
  var placeholderAccount: Account {
    Account(id: accountId, avatar: accountId, name: accountId)
  }
  
  init(accountId: Account.ID, selection: Binding<String?>) {
    self.accountId = accountId
    self._selection = selection
  }
  
  var body: some View {
    NavigationLink(
      destination: DeploymentListView(accountId: accountId),
      tag: accountId,
      selection: $selection
    ) {
      LoadableObjectView(
        value: api.account,
        placeholderData: Account.mockData
      ) { account in
        Label(
          title: {
          VStack(alignment: .leading) {
            Text(account.name)

            if account.id.isTeam {
              Text("Team Account")
                .font(.caption)
                .foregroundColor(.secondary)
            }
          }
        },
        icon: {
          VercelUserAvatarView(
            avatarID: account.avatar,
            teamID: account.id.isTeam ? account.id : nil,
            size: avatarSize)
        })
      }
    }.onAppear {
      api.loadAccount()
    }
//    AsyncContentView(
//      source: AccountViewModel(accountId: accountId),
//      placeholderData: placeholderAccount,
//      allowsRetries: false
//    ) { account in
//      Label(
//        title: {
//          VStack(alignment: .leading) {
//            Text(account.name)
//
//            if account.isTeam {
//              Text("Team Account")
//                .font(.caption)
//                .foregroundColor(.secondary)
//            }
//          }
//        },
//        icon: {
//          VercelUserAvatarView(
//            avatarID: account.avatar,
//            teamID: account.isTeam ? account.id : nil,
//            size: avatarSize)
//        }
//      )
//    }
  }
}

struct AccountListRowView_Previews: PreviewProvider {
    static var previews: some View {
      AccountListRowView(accountId: "v9dklkDUzwdLE3GZaVteSbJq", selection: .constant(""))
    }
}
