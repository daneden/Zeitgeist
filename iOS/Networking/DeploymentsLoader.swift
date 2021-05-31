//
//  DeploymentsLoader.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

struct DeploymentsResponse: Decodable {
  var deployments: [Deployment]
}

class DeploymentsLoader {
  private let decoder = JSONDecoder()
  
  func loadDeployments(withID id: Account.ID, completion: @escaping (Result<[Deployment]>) -> Void) {
    let isTeam = id.starts(with: "team_")
    let urlPath = "v5/now/deployments"
    guard let url = URL(string: "https://api.vercel.com/\(urlPath)?teamId=\(isTeam ? id : "")&limit=100") else {
      return
    }
    
    guard let token = KeychainItem(account: id).wrappedValue else {
      completion(.failure(SessionError.notAuthenticated))
      return
    }
    
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    // Synchronously check and return a cached value if there's one available
    let cache = URLCache.shared
    if let cachedResponse = cache.cachedResponse(for: request) {
      let data = cachedResponse.data
      let decoded = try? self.decoder.decode(DeploymentsResponse.self, from: data)
      if let deployments = decoded?.deployments {
        completion(.success(deployments))
      }
    }
    
    // Asynchronously fetch data from origin, updating the cache automatically,
    // and invoke the completion callback again once received
    URLSession.shared.dataTask(with: request) { data, response, error in
      guard let data = data,
            let decoded = try? self.decoder.decode(DeploymentsResponse.self, from: data) else {
        completion(.failure(LoaderError.decodingError))
        return
      }
      
      completion(.success(decoded.deployments))
    }.resume()
  }
}
