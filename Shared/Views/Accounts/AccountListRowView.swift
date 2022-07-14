//
//  AccountListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/07/2022.
//

import SwiftUI

struct AccountListRowView: View {
  var accountId: VercelAccount.ID
  
  @State private var account: VercelAccount?
  
  var body: some View {
    HStack {
      if let account = account {
        VercelUserAvatarView(account: account)
        
        VStack(alignment: .leading) {
          Text(account.name)
          
          if account.isTeam {
            Text("Team Account").foregroundStyle(.secondary)
          }
        }
      } else {
        ProgressView()
        Text("Loading")
      }
    }
    .task {
      let session = VercelSession()
      session.accountId = accountId
      account = await session.loadAccount()
    }
  }
}

struct AccountListRowView_Previews: PreviewProvider {
    static var previews: some View {
      AccountListRowView(accountId: "12345")
    }
}
