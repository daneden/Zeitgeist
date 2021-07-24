//
//  VercelAPI.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation
import Combine

enum Result<T> {
  case success(_: T)
  case failure(_: Error)
}

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

enum LoadingState<Value> {
  case idle
  case loading
  case failed(Error)
  case loaded(Value)
  case refreshing(Value)
}

enum RequestMethod: String, RawRepresentable {
  case GET, PUT, PATCH, DELETE, POST
}

class VercelAPI: ObservableObject {
  private var disposables: [AnyCancellable?] = []
  
  @Published private(set) var account: LoadingState<Account> = .loading
  @Published private(set) var deployments: LoadingState<[Deployment]> = .loading
  @Published private(set) var aliases: [String: [Alias]] = [:]
  
  private let decoder: JSONDecoder
  
  init(accountId: Account.ID) {
    let config = URLSessionConfiguration.default
    
    if let token = KeychainItem(account: accountId).wrappedValue {
      config.httpAdditionalHeaders = [
        "Authorization": "Bearer \(token)"
      ]
    }
    
    config.urlCache = .shared
    config.requestCachePolicy = .reloadRevalidatingCacheData
    config.timeoutIntervalForRequest = 60
    config.timeoutIntervalForResource = 120
    
    self.accountId = accountId
    self.session = URLSession(configuration: config)
    
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .secondsSince1970
    self.decoder = decoder
  }
  
  private let accountId: Account.ID
  let session: URLSession
  
  enum DeploymentsEndpointVersion: String {
    case v5, v11, v12
  }
  
  func makeRequest(
    for endpoint: Endpoint,
    queryItems: [URLQueryItem] = [],
    method: RequestMethod = .GET
  ) -> URLRequest {
    return VercelAPI.makeRequest(for: endpoint, with: accountId, queryItems: queryItems, method: method)
  }
  
  func request<T: Decodable>(endpoint: Endpoint,
                             resourceType: T.Type = T.self,
                             queryItems: [URLQueryItem] = [],
                             method: RequestMethod = .GET) -> AnyPublisher<T, LoaderError> {
    let request = self.makeRequest(for: endpoint, queryItems: queryItems, method: method)
    
    return self.session.dataTaskPublisher(for: request)
      .tryMap({ try VercelAPI.processResponse(data: $0.data, response: $0.response) })
      .mapError { _ in LoaderError.unauthorized }
      .decode(type: T.self, decoder: decoder)
      .mapError { _ in LoaderError.decodingError }
      .eraseToAnyPublisher()
  }
  
  static func processResponse(data: Data, response: URLResponse) throws -> Data {
    guard let httpResponse = response as? HTTPURLResponse else {
      throw LoaderError.unknown
    }
    if (httpResponse.statusCode == 404) {
      throw LoaderError.unknown
    }
    if 200 ... 299 ~= httpResponse.statusCode {
      return data
    } else {
      do {
        throw LoaderError.unauthorized
      } catch _ {
        throw LoaderError.unknown
      }
    }
  }
}

extension VercelAPI {
  func loadAccount() {
    let cancellable = self.request(endpoint: .viewer(viewerId: accountId), resourceType: Account.self)
      .receive(on: DispatchQueue.main)
      .sink { completion in
        print(completion)
      } receiveValue: { account in
        self.account = .loaded(account)
      }
    
    disposables.append(cancellable)
  }
  
  func loadDeployments() {
    let cancellable = self.request(endpoint: .deployments(), resourceType: DeploymentsResponse.self)
      .receive(on: DispatchQueue.main)
      .sink { completion in
        print(completion)
      } receiveValue: { deploymentsResponse in
        self.deployments = .loaded(deploymentsResponse.deployments)
      }
    
    disposables.append(cancellable)
  }
  
  func loadAliases(for deploymentId: Deployment.ID) {
    let cancellable = self.request(endpoint: .aliases(deploymentId: deploymentId), resourceType: Alias.NetworkResponse.self)
      .receive(on: DispatchQueue.main)
      .sink { completion in
        print(completion)
      } receiveValue: { response in
        self.aliases[deploymentId] = response.result
      }
    
    disposables.append(cancellable)
  }
}

extension VercelAPI {
  static private let URL_PREFIX = "https://"
  static private let HOST = "api.vercel.com"
  
  enum Endpoint {
    case deployment(id: Deployment.ID, version: DeploymentsEndpointVersion = .v5)
    case cancelDeployment(id: Deployment.ID)
    case deployments(version: DeploymentsEndpointVersion = .v5)
    case aliases(deploymentId: Deployment.ID)
    case viewer(viewerId: Account.ID)
    
    func path() -> String {
      switch self {
      case .cancelDeployment(let id):
        return "\(Endpoint.deployment(id: id, version: .v12))/cancel"
      case .deployment(let id, let version):
        return "\(Endpoint.deployments(version: version).path())/\(id)"
      case .deployments(let version):
        return "\(version.rawValue)/now/deployments"
      case .aliases(let deploymentId):
        return "\(Endpoint.deployments().path())/\(deploymentId)/aliases"
      case .viewer(let viewerId):
        return viewerId.starts(with: "team_") ? "v1/teams/\(viewerId)" : "www/user"
      }
    }
  }
  
  static func makeRequest(
    for endpoint: Endpoint,
    with accountId: Account.ID,
    queryItems: [URLQueryItem] = [],
    method: RequestMethod = .GET
  ) -> URLRequest {
    var urlComponents = URLComponents(string: "https://api.vercel.com/\(endpoint.path())")!
    var completeQuery = queryItems
    
    completeQuery.append(URLQueryItem(name: "userId", value: accountId))
    
    if accountId.isTeam {
      completeQuery.append(URLQueryItem(name: "teamId", value: accountId))
    }
    
    urlComponents.queryItems = completeQuery
    
    var request = URLRequest(url: urlComponents.url!)
    request.httpMethod = method.rawValue
    
    return request
  }
}
