//
//  AliasesViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import Foundation
import Combine
import SwiftUI

struct Alias: Codable, Hashable {
  var uid: String
  var alias: String
  var url: URL {
    URL(string: "https://\(alias)")!
  }
  
  enum CodingKeys: String, CodingKey {
    case uid, alias
  }
}

struct AliasesResponse: Codable {
  var aliases: [Alias]
}

class AliasesViewModel: LoadableObject {
  @AppStorage("refreshFrequency") private var refreshFrequency: Double = 5.0
  typealias Output = [Alias]
  
  @Published private(set) var state: LoadingState<Output> = .idle {
    didSet {
      if case .loaded(let aliases) = state {
        value = aliases
      }
    }
  }
  
  @Published private(set) var value: Output?
  
  private var request: URLRequest {
    try! VercelAPI.request(
      for: .deployments(
        version: 5,
        deploymentID: deploymentId,
        path: "aliases"
      ),
      with: accountId
    )
  }
  
  private let accountId: Account.ID
  private let deploymentId: Deployment.ID
  
  init(accountId: Account.ID, deploymentId: Deployment.ID) {
    self.accountId = accountId
    self.deploymentId = deploymentId
    
    if let cachedData = loadCachedData() {
      state = .loaded(cachedData)
    }
  }
  
  func load() async {
    switch state {
    case .loaded(_):
      break
    default:
      state = .loading
    }
    
    do {
      let watcher = URLRequestWatcher(urlRequest: request, delay: Int(refreshFrequency))
      
      for try await data in watcher {
        let newData = try JSONDecoder().decode(AliasesResponse.self, from: data).aliases
        
        DispatchQueue.main.async {
          self.state = .loaded(newData)
        }
      }
    } catch {
      print(error.localizedDescription)
    }
  }
  
  func loadOnce() async -> [Alias]? {
    do {
      let (data, _) = try await URLSession.shared.data(for: request)
      
      return try? JSONDecoder().decode(AliasesResponse.self, from: data).aliases
    } catch {
      return nil
    }
  }
}

extension AliasesViewModel {
  func loadCachedData() -> Output? {
    if let data = URLCache.shared.cachedResponse(for: request)?.data,
       let decodedData = try? JSONDecoder().decode(AliasesResponse.self, from: data).aliases {
      return decodedData
    }
    
    return nil
  }
}
