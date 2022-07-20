//
//  AccountListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct AccountListView: View {
  @EnvironmentObject var session: VercelSession
  @State var signInModel = SignInViewModel()
  
  var body: some View {
    List {
      Section {
        Picker(selection: $session.accountId) {
          ForEach(Preferences.authenticatedAccountIds, id: \.self) { accountId in
            AccountListRowView(accountId: accountId)
              .tag(accountId)
              .contextMenu {
                Button(role: .destructive) {
                  VercelSession.deleteAccount(id: accountId)
                } label: {
                  Label("Delete Account", systemImage: "person.badge.minus")
                }
              }
          }
          .onDelete(perform: deleteAccount)
          .onMove(perform: move)
        } label: {
          Text("Selected Account")
        }
        .pickerStyle(.inline)
      }
      
      Section {
        Button(action: { signInModel.signIn() }) {
          Label("Add New Account", systemImage: "person.badge.plus")
        }
      }
    }.toolbar {
      EditButton()
    }
  }
  
  func deleteAccount(at offsets: IndexSet) {
    let ids = offsets.map { offset in
      Preferences.authenticatedAccountIds[offset]
    }
    
    for id in ids {
      VercelSession.deleteAccount(id: id)
    }
  }
  
  func move(from source: IndexSet, to destination: Int) {
    Preferences.authenticatedAccountIds.move(fromOffsets: source, toOffset: destination)
  }
}

struct AccountListView_Previews: PreviewProvider {
  static var previews: some View {
      AccountListView()
  }
}
