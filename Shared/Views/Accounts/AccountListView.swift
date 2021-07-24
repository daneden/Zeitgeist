//
//  AccountListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct AccountListView: View {
  @EnvironmentObject var session: Session
  @State var signInModel = SignInViewModel()
  @SceneStorage("activeAccountID") var activeAccountID: Account.ID?
  
  var body: some View {
    List(selection: $activeAccountID) {
      Section(header: Text("Accounts")) {
        ForEach(session.authenticatedAccountIds, id: \.self) { accountId in
          AccountListRowView(accountId: accountId, selection: $activeAccountID)
            .contextMenu {
              Button(action: { session.deleteAccount(id: accountId)}) {
                Label("Remove Account", systemImage: "person.badge.minus")
              }.foregroundColor(.systemRed)
            }
            .tag(accountId)
        }
        .onDelete(perform: deleteAccount)
        .onMove(perform: move)
        
        Button(action: { signInModel.signIn() }) {
          HStack {
            Label("Add Account", systemImage: "person.badge.plus")
            Spacer()
          }
          .contentShape(Rectangle())
        }
          .buttonStyle(PlainButtonStyle())
      }
      
      Group {
        NavigationLink(destination: SettingsView()) {
          Label("Settings", systemImage: "gearshape")
        }
      }
    }
    .id(session.uuid)
    .toolbar {
      #if !os(macOS)
      EditButton()
      #endif
    }
    .navigationTitle("Zeitgeist")
    .onOpenURL(perform: { url in
      switch url.detailPage {
      case .account(let id):
        self.activeAccountID = id
      case .deployment(let id, _):
        self.activeAccountID = id
      default:
        return
      }
    })
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
