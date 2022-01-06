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
  
  private let accountId: Account.ID
  private let deploymentId: Deployment.ID
  
  init(accountId: Account.ID, deploymentId: Deployment.ID) {
    self.accountId = accountId
    self.deploymentId = deploymentId
  }
  
  func load() async {
    switch state {
    case .loaded(_):
      break
    default:
      state = .loading
    }
    
    do {
      let request = try VercelAPI.request(for: .deployments, with: accountId, appending: "\(deploymentId)/aliases")
      let watcher = URLRequestWatcher(urlRequest: request, delay: Int(refreshFrequency))
      
      for try await data in watcher {
        let newData = try JSONDecoder().decode(AliasesResponse.self, from: data).aliases
        
        DispatchQueue.main.async {
          self.state = .loaded(newData)
        }
        
        saveCachedData(data: data, key: cacheKey)
      }
    } catch {
      print(error.localizedDescription)
    }
  }
}

extension AliasesViewModel {
  private var cacheKey: String {
    "__cache__aliases-\(deploymentId)"
  }
  
  func saveCachedData(data: Data, key: String) {
    UserDefaults.standard.set(data, forKey: key)
  }
  
  func loadCachedData(key: String) -> Output? {
    if let data = UserDefaults.standard.data(forKey: key),
       let decodedData = try? JSONDecoder().decode(AliasesResponse.self, from: data).aliases {
      return decodedData
    }
    
    return nil
  }
}
