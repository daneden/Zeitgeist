//
//  AccountViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

struct Account: Codable, Identifiable {
  typealias ID = String
  var id: ID
  var isTeam: Bool {
    id.starts(with: "team_")
  }
  var avatar: String?
  var name: String
}

class AccountViewModel: LoadableObject {
  @Published private(set) var state: LoadingState<Account> = .idle
  
  typealias Output = Account
  
  private let accountId: Account.ID
  private let loader: AccountLoader
  
  init(accountId: Account.ID, loader: AccountLoader = .init()) {
    self.accountId = accountId
    self.loader = loader
  }
  
  func load() {
    state = .loading
    
    loader.loadAccount(withID: accountId) { [weak self] result in
      switch result {
      case .success(let account):
        DispatchQueue.main.async {
          self?.state = .loaded(account)
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self?.state = .failed(error)
        }
      }
    }
  }
}
