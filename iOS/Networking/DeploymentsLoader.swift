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
  var useURLCache = true
  
  func loadDeployments(withID id: Account.ID, completion: @escaping (Result<[Deployment]>) -> Void) {
    do {
      let request = try VercelAPI.request(for: .deployments, with: id, queryItems: [URLQueryItem(name: "limit", value: "100")])
      
      // Synchronously check and return a cached value if there's one available
      if useURLCache {
        let cache = URLCache.shared
        if let cachedResponse = cache.cachedResponse(for: request) {
          let data = cachedResponse.data
          let decoded = try? self.decoder.decode(DeploymentsResponse.self, from: data)
          if let deployments = decoded?.deployments {
            completion(.success(deployments))
          }
        }
      }
      
      // Asynchronously fetch data from origin, updating the cache automatically,
      // and invoke the completion callback again once received
      URLSession.shared.dataTask(with: request) { data, response, error in
        if let response = response as? HTTPURLResponse,
           response.statusCode == 403 {
          completion(.failure(LoaderError.unauthorized))
          URLCache.shared.removeAllCachedResponses()
          return
        }
        
        guard let data = data,
              let decoded = try? self.decoder.decode(DeploymentsResponse.self, from: data) else {
          completion(.failure(LoaderError.decodingError))
          return
        }
        
        completion(.success(decoded.deployments))
      }.resume()
    } catch {
      completion(.failure(error))
    }
  }
}
