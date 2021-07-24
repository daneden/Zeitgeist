//
//  AccountLoader.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

class AccountLoader {
  private let decoder = JSONDecoder()
  
  func loadAccount(withID id: Account.ID, completion: @escaping (Result<Account>) -> Void) {
    let request = VercelAPI.makeRequest(for: .viewer(viewerId: id), with: id)
    
    URLSession.shared.dataTask(with: request) { data, response, error in
      if let response = response as? HTTPURLResponse,
         response.statusCode == 403 {
        completion(.failure(LoaderError.unauthorized))
        URLCache.shared.removeAllCachedResponses()
        Session.shared.revalidate()
        return
      }
      
      guard let data = data, let account = self.handleResponseData(data: data, isTeam: id.isTeam) else {
        completion(.failure(LoaderError.decodingError))
        return
      }
      
      completion(.success(account))
    }.resume()
  }
  
  func handleResponseData(data: Data, isTeam: Bool) -> Account? {
    var account: Account
    
    if isTeam {
      guard let decoded = try? self.decoder.decode(Team.self, from: data) else {
        return nil
      }
      
      account = Account(id: decoded.id, avatar: decoded.avatar, name: decoded.name)
    } else {
      guard let decoded = try? self.decoder.decode(User.NetworkResponse.self, from: data) else {
        return nil
      }
      
      account = Account(id: decoded.user.id, avatar: decoded.user.avatar, name: decoded.user.name)
    }
    
    return account
  }
}
