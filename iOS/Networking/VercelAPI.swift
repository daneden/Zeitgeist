//
//  VercelAPI.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation

struct VercelAPI {
  enum Path: String {
    case deployments = "v5/now/deployments/"
    case deploymentsV11 = "v11/now/deployments/"
    case deploymentsV12 = "v12/now/deployments/"
  }
  
  enum RequestMethod: String, RawRepresentable {
    case GET, PUT, PATCH, DELETE
  }
  
  static func request(
    for path: Path,
    with accountId: Account.ID,
    queryItems: [URLQueryItem] = [],
    appending: String? = nil,
    method: RequestMethod = .GET
  ) throws -> URLRequest {
    let isTeam = accountId.starts(with: "team_")
    var urlComponents = URLComponents(string: "https://api.vercel.com/\(path.rawValue)\(appending ?? "")")!
    var completeQuery = queryItems
    
    if isTeam {
      completeQuery.append(URLQueryItem(name: "teamId", value: accountId))
    }
    
    urlComponents.queryItems = completeQuery
    
    guard let token = KeychainItem(account: accountId).wrappedValue else {
      throw LoaderError.unauthorized
    }
    var request = URLRequest(url: urlComponents.url!)
    request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.httpMethod = method.rawValue
    
    return request
  }
}
