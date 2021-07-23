//
//  DeploymentViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import Foundation
import Combine
import SwiftUI

class DeploymentsViewModel: LoadableObject {
  typealias Output = [Deployment]
  
  @Published private(set) var state: LoadingState<Output> = .idle
  @AppStorage("refreshFrequency") var refreshFrequency: Double = 5.0
  
  private var mostRecentDeployments: [Deployment] = []
  
  private var timer: Timer?
  
  private let accountId: Account.ID
  private let loader: DeploymentsLoader
  
  init(accountId: Account.ID, loader: DeploymentsLoader = DeploymentsLoader()) {
    self.accountId = accountId
    self.loader = loader
    
    self.timer = Timer.scheduledTimer(withTimeInterval: refreshFrequency, repeats: true) { [weak self] _ in
      self?.load()
    }
  }
  
  deinit {
    timer?.invalidate()
    timer = nil
  }
  
  func load() {
    if mostRecentDeployments.isEmpty {
      state = .loading
    } else {
      state = .refreshing(mostRecentDeployments)
    }
    
    loader.loadDeployments(withID: accountId) { [weak self] result in
      switch result {
      case .success(let deployments):
        DispatchQueue.main.async {
          if self?.mostRecentDeployments.elementsEqual(deployments) == false {
            withAnimation { self?.state = .loaded(deployments) }
            self?.mostRecentDeployments = deployments
          }
        }
      case .failure(let error):
        DispatchQueue.main.async {
          self?.state = .failed(error)
        }
      }
    }
  }
}
