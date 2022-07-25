//
//  AccountListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/07/2022.
//

import SwiftUI

struct AccountListRowView: View {
  var accountId: VercelAccount.ID
  
  var account: VercelAccount? {
    tempSession.account
  }
  
  @StateObject private var tempSession = VercelSession()
  
  var body: some View {
    Group {
      if let account = account {
        Label {
          VStack(alignment: .leading) {
            Text(account.name)
            
            if account.isTeam {
              Text("Team Account")
                .foregroundStyle(.secondary)
                .font(.caption)
            }
          }
        } icon: {
          VercelUserAvatarView(account: account)
        }
      } else {
        ProgressView("Loading")
      }
    }
    .onAppear {
      tempSession.accountId = accountId
    }
    .id(account?.name ?? accountId)
  }
}

struct AccountListRowView_Previews: PreviewProvider {
    static var previews: some View {
      AccountListRowView(accountId: "12345")
    }
}
