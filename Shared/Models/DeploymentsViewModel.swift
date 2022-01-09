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
  @AppStorage("refreshFrequency") var refreshFrequency: Double = 5.0
  @Published var state: LoadingState<[Deployment]> = .idle
  
  private var request: URLRequest? {
    try? VercelAPI.request(
      for: .deployments(version: 5),
      with: accountId,
      queryItems: [URLQueryItem(name: "limit", value: "100")]
    )
  }

  var mostRecentDeployments: [Deployment] {
    if case .loaded(let deployments) = state {
      return deployments
    } else {
      return []
    }
  }

  private let accountId: Account.ID

  init(accountId: Account.ID) {
    self.accountId = accountId
    
    if let cachedData = loadCachedData() {
      self.state = .loaded(cachedData)
    }
  }

  func load() async {
    switch self.state {
    case .loaded(_):
      break
    default:
      self.state = .loading
    }
    
    guard let request = request else {
      return
    }
    
    do {
      let watcher = URLRequestWatcher(urlRequest: request, delay: Int(refreshFrequency))
      
      for try await data in watcher {
        let newData = try JSONDecoder().decode(DeploymentsResponse.self, from: data).deployments
        
        DispatchQueue.main.async {
          withAnimation {
            self.state = .loaded(newData)
          }
        }
      }
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func loadOnce() async -> [Deployment]? {
    guard let request = request else {
      return nil
    }

    do {
      let (data, _) = try await URLSession.shared.data(for: request)
      
      return try? JSONDecoder().decode(DeploymentsResponse.self, from: data).deployments
    } catch {
      return nil
    }
  }
}

extension DeploymentsViewModel {
  func loadCachedData() -> [Deployment]? {
    if let request = request,
       let cachedResults = URLCache.shared.cachedResponse(for: request),
       let decodedResults = try? JSONDecoder().decode(DeploymentsResponse.self, from: cachedResults.data).deployments {
      return decodedResults
    }
    
    return nil
  }
}
