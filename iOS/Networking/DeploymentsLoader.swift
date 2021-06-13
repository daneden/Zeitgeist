//
//  DeploymentsLoader.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import Combine

class DeploymentsLoader {
  private let decoder = JSONDecoder()
  var useURLCache = true
  var subscriptions = Set<AnyCancellable>()
  
  func loadDeployments(withID id: Account.ID, completion: @escaping (Result<[Deployment]>) -> Void) {
    do {
      let request = try VercelAPI.request(for: .deployments, with: id, queryItems: [URLQueryItem(name: "limit", value: "100")])
      
      URLSession.shared.publisher(for: request, responseType: Deployment.NetworkResponse.self)
        .sink { result in
          switch result {
          case let .failure(error):
            print(error.localizedDescription)
            completion(.failure(error))
          case .finished:
            break
          }
        } receiveValue: { response in
          completion(.success(response.deployments))
        }
        .store(in: &subscriptions)
    } catch {
      completion(.failure(error))
    }
  }
}
