//
//  AccountListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct AccountListView: View {
  @EnvironmentObject var session: Session
  var body: some View {
    List {
      Section(header: Text("Accounts")) {
        ForEach(session.authenticatedAccountIds, id: \.self) { accountId in
          NavigationLink(destination: DeploymentListView(accountId: accountId)) {
            AccountListRowView(accountId: accountId)
          }
          .contextMenu {
            Button(action: { session.deleteAccount(id: accountId)}) {
              Label("Delete Account", systemImage: "trash")
            }.foregroundColor(.systemRed)
          }
        }
        .onDelete(perform: deleteAccount)
        .onMove(perform: move)
        
        AddAccountButton(label: "Add Account", iconName: "person.badge.plus")
          .buttonStyle(PlainButtonStyle())
      }
    }
    .navigationTitle("Zeitgeist")
  }
  
  func deleteAccount(at offsets: IndexSet) {
    let ids = offsets.map { offset in
      session.authenticatedAccountIds[offset]
    }
    
    for id in ids {
      session.deleteAccount(id: id)
    }
  }
  
  func move(from source: IndexSet, to destination: Int) {
    session.authenticatedAccountIds.move(fromOffsets: source, toOffset: destination)
  }
}

struct AccountListView_Previews: PreviewProvider {
  static var previews: some View {
      AccountListView()
  }
}
