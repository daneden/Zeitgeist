//
//  VercelAPI.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation

enum LoaderError: Error {
  case unknown
  case decodingError
  case unauthorized
}

extension LoaderError: LocalizedError {
  var errorDescription: String? {
    switch self {
    case .unauthorized:
      return "The request couldn’t be authorized. Try deleting and re-authenticating your account."
    default:
      return "An unknown error occured: \(self)"
    }
  }
}

struct VercelAPI {
  enum Path {
    case deployments(
      version: Int = 6,
      deploymentID: VercelDeployment.ID? = nil,
      path: String? = nil
    )
    
    case projects
    
    case account(id: VercelAccount.ID)
    
    var subPaths: [String] {
      switch self {
      case .deployments(_, let deploymentID, let path):
        return [deploymentID, path].compactMap({ $0 })
      case .projects: return []
      case .account(_): return []
      }
    }
    
    var resolvedPath: String {
      switch self {
      case .deployments(let version, _, _):
        return "v\(version)/deployments/\(subPaths.joined(separator: "/"))"
      case .projects:
        return "v9/projects"
      case .account(let id):
        let isTeam = id.isTeam
        return isTeam ? "v2/teams/\(id)" : "v2/user"
      }
    }
  }
  
  enum RequestMethod: String, RawRepresentable {
    case GET, PUT, PATCH, DELETE, POST
  }
  
  static func request(for path: Path,
                      with accountID: VercelAccount.ID,
                      queryItems: [URLQueryItem] = [],
                      method: RequestMethod = .GET
  ) -> URLRequest {
    let isTeam = accountID.isTeam
    var urlComponents = URLComponents(string: "https://api.vercel.com/\(path.resolvedPath)")!
    var completeQuery = queryItems
    
    completeQuery.append(URLQueryItem(name: "userId", value: accountID))
    
    if isTeam {
      completeQuery.append(URLQueryItem(name: "teamId", value: accountID))
    }
    
    urlComponents.queryItems = completeQuery
    
    var request = URLRequest(url: urlComponents.url!)
    request.httpMethod = method.rawValue
    
    return request
  }
}
