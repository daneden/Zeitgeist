//
//  AccountView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 20/07/2022.
//

import SwiftUI

struct AccountView: View {
  @EnvironmentObject var session: VercelSession
  var body: some View {
    return Form {
      Section {
        NavigationLink(destination: AccountListView()) {
          if let account = session.account {
            Label {
              Text(account.name)
            } icon: {
              VercelUserAvatarView(account: account)
            }
          }
        }
      }
    }
  }
}
