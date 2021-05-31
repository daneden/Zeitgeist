//
//  DeploymentViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import Foundation
import Combine

class DeploymentsViewModel: LoadableObject {
  @Published private(set) var state: LoadingState<[Deployment]> = .idle
  
  private var timer: Timer?
  
  typealias Output = [Deployment]
  
  private let accountId: Account.ID
  private let loader: DeploymentsLoader
  
  init(accountId: Account.ID, loader: DeploymentsLoader = DeploymentsLoader()) {
    self.accountId = accountId
    self.loader = loader
    
    self.timer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
      self?.load()
    }
  }
  
  deinit {
    timer?.invalidate()
    timer = nil
  }
  
  func load() {
    state = .loading
    
    loader.loadDeployments(withID: accountId) { [weak self] result in
      switch result {
      case .success(let deployments):
        DispatchQueue.main.async {
          self?.state = .loaded(deployments)
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self?.state = .failed(error)
        }
      }
    }
  }
}
