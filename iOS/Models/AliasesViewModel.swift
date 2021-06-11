//
//  AliasesViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import Foundation
import Combine

class AliasesViewModel: LoadableObject {
  typealias Output = [Alias]
  @Published private(set) var state: LoadingState<Output> = .idle
  
  private let accountId: Account.ID
  private let deploymentId: Deployment.ID
  private let loader: AliasesLoader
  
  init(accountId: Account.ID, deploymentId: Deployment.ID, loader: AliasesLoader = AliasesLoader()) {
    self.accountId = accountId
    self.deploymentId = deploymentId
    self.loader = loader
  }
  
  func load() {
    state = .loading
    
    loader.loadAliases(withAccountID: accountId, forDeploymentID: deploymentId) { [weak self] result in
      switch result {
      case .success(let aliases):
        DispatchQueue.main.async {
          self?.state = .loaded(aliases)
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self?.state = .failed(error)
        }
      }
    }
  }
}
