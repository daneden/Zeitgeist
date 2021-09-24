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
  @Published private(set) var state: LoadingState<Output> = .idle {
    didSet {
      if case .loaded(let aliases) = state {
        value = aliases
      }
    }
  }
  @Published private(set) var value: Output?
  
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
  
  func loadAsync() async {
    DispatchQueue.main.async {
      self.state = .loading
    }
    
    let result = await loader.loadAliases(withAccountID: accountId, forDeploymentID: deploymentId)
    
    DispatchQueue.main.async {
      switch result {
      case .success(let aliases):
        self.state = .loaded(aliases)
      case .failure(let error):
        self.state = .failed(error)
      }
    }
  }
}
