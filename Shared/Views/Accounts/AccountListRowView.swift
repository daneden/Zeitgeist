//
//  AccountListRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/07/2022.
//

import SwiftUI

struct AccountListRowView: View {
  var account: VercelAccount?
  
  var body: some View {
    Group {
      if let account = account {
        Label {
          VStack(alignment: .leading) {
            Text(account.name ?? account.username)
            
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
    .id(account?.id)
  }
}

struct AccountListRowView_Previews: PreviewProvider {
    static var previews: some View {
      AccountListRowView()
    }
}
