//
//  AliasesLoader.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation


class AliasesLoader {
  private let decoder = JSONDecoder()
  
  func loadAliases(withAccountID accountId: Account.ID, forDeploymentID deploymentId: Deployment.ID, completion: @escaping (Result<[Alias]>) -> Void) {
    do {
      let request = try VercelAPI.request(for: .deployments, with: accountId, appending: "\(deploymentId)/aliases")
      
      let cache = URLCache.shared
      
      if let cachedResponse = cache.cachedResponse(for: request) {
        let data = cachedResponse.data
        let decoded = try? self.decoder.decode(AliasesResponse.self, from: data)
        if let aliases = decoded?.aliases {
          completion(.success(aliases))
        }
      }
      
      URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data,
              let decoded = try? self.decoder.decode(AliasesResponse.self, from: data) else {
          completion(.failure(LoaderError.decodingError))
          return
        }
        
        completion(.success(decoded.aliases))
      }.resume()
    } catch {
      completion(.failure(error))
    }
  }
  
  func loadAliases(withAccountID accountId: Account.ID, forDeploymentID deploymentId: Deployment.ID) async -> Result<[Alias]> {
    do {
      let request = try VercelAPI.request(for: .deployments, with: accountId, appending: "\(deploymentId)/aliases")
      
      let cache = URLCache.shared
      
      if let cachedResponse = cache.cachedResponse(for: request) {
        let data = cachedResponse.data
        let decoded = try? self.decoder.decode(AliasesResponse.self, from: data)
        if let aliases = decoded?.aliases {
          return .success(aliases)
        }
      }
      
      let (data, _) = try await URLSession.shared.data(for: request)
      
      guard let decoded = try? self.decoder.decode(AliasesResponse.self, from: data) else {
        return .failure(LoaderError.decodingError)
      }
        
      return .success(decoded.aliases)
    } catch {
      return .failure(error)
    }
  }
}
