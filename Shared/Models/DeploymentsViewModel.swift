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
  @Published private(set) var state: LoadingState<[Deployment]> = .idle

  private var mostRecentDeployments: [Deployment] = []

  typealias Output = [Deployment]

  private let accountId: Account.ID
  private let loader: DeploymentsLoader

  init(accountId: Account.ID, loader: DeploymentsLoader = DeploymentsLoader()) {
    self.accountId = accountId
    self.loader = loader
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

  func loadAsync() async {
    DispatchQueue.main.async {
      switch self.state {
      case .loaded(_):
        break
      default:
        self.state = .loading
      }
    }

    guard let result = try? await loader.loadDeployments(withID: accountId) else {
      state = .failed(LoaderError.unknown)
      return
    }

    DispatchQueue.main.async {
      switch result {
      case .success(let deployments):
        if self.mostRecentDeployments.elementsEqual(deployments) == false {
          withAnimation { self.state = .loaded(deployments) }
        } else {
          self.state = .loaded(deployments)
        }

        self.mostRecentDeployments = deployments
      case .failure(let error):
        self.state = .failed(error)
      }
    }
  }
}
