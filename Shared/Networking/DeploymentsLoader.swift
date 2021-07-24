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
    let request = VercelAPI.makeRequest(for: .deployments(), with: id, queryItems: [URLQueryItem(name: "limit", value: "100")])
    
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
  }
}
