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
  @AppStorage("refreshFrequency") var refreshFrequency: Double = 5.0
  @Published private(set) var state: LoadingState<[Deployment]> = .idle

  internal let cache: Cache
  
  var mostRecentDeployments: [Deployment] {
    if case .loaded(let deployments) = state {
      return deployments
    } else {
      return []
    }
  }

  typealias Output = [Deployment]

  private let accountId: Account.ID
  
  private var cacheKey: String {
    "__cache__deployments-\(accountId)"
  }

  init(accountId: Account.ID) {
    self.accountId = accountId
    self.cache = Cache()
    
    if let cachedData = cache[cacheKey],
       let decoded = try? JSONDecoder().decode(Output.self, from: cachedData) {
      self.state = .loaded(decoded)
    }
  }

  func load() async {
    switch self.state {
    case .loaded(_):
      break
    default:
      self.state = .loading
    }
    
    do {
      let request = try VercelAPI.request(for: .deployments, with: accountId, queryItems: [URLQueryItem(name: "limit", value: "100")])
      let watcher = URLRequestWatcher(urlRequest: request, delay: Int(refreshFrequency))
      
      for try await data in watcher {
        let newData = try JSONDecoder().decode(DeploymentsResponse.self, from: data).deployments
        
        DispatchQueue.main.async {
          withAnimation {
            self.state = .loaded(newData)
          }
        }
        
        cache[cacheKey] = data
      }
    } catch {
      print(error.localizedDescription)
    }
  }
}
