//
//  VercelFetcher.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 06/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

enum FetcherError: Error {
  case decoding, fetching, updating
}

enum VercelRoute: String {
  case teams = "v1/teams"
  case deployments = "v6/now/deployments"
  case projects = "v6/projects"
  case user = "www/user"
}

public class VercelFetcher: ObservableObject {
  enum FetchState {
    case loading
    case finished
    case error
    case idle
  }
  
  private let decoder = JSONDecoder()
  
  @Published var account: VercelAccount
  @Published var deployments = [Deployment]()
  @Published var projects = [Project]()
  @Published var fetchState: FetchState = .idle
  
  private var pollingTimer: Timer?
  
  init(account: VercelAccount, withTimer: Bool? = nil) {
    self.account = account
    
    if withTimer == true {
      self.resetTimers()
    }
    
    self.tick()
  }
  
  deinit {
    resetTimers(reinit: false)
  }
  
  func resetTimers(reinit: Bool = true) {
    pollingTimer?.invalidate()
    pollingTimer = nil
    
    if reinit {
      pollingTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { [weak self] _ in
        self?.tick()
      })
      
      pollingTimer?.tolerance = 0.5
      RunLoop.current.add(pollingTimer!, forMode: .common)
      pollingTimer?.fire()
    }
  }
  
  func tick() {
    self.loadAccount()
    self.loadDeployments()
  }
  
  // MARK: Helper Functions
  func urlForRoute(_ route: VercelRoute, appending: String? = nil, queryItems: [URLQueryItem] = .init()) -> URL {
    let query = account.isTeam ? queryItems + [URLQueryItem(name: "teamId", value: account.id)] : queryItems
    var urlComponents = URLComponents(string: "https://api.vercel.com/\(route.rawValue)\(appending ?? "")")!
    urlComponents.queryItems = query
    return urlComponents.url!
  }
  
  func getHeaders() -> [String: String]? {
    let token = KeychainItem(account: account.id)
    var headers = [
      "Content-Type": "application/json",
      "User-Agent": "ZG Client \(APP_VERSION)"
    ]
    
    if let token = token.wrappedValue {
      headers["Authorization"] = "Bearer \(token)"
    }
    
    return headers
  }
  
  func fetch<T>(request: URLRequest, decodingType: T.Type, completion: @escaping (T?, Error?) -> Void) where T: Decodable {
    let decoder = JSONDecoder()
    self.fetchState = .loading
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      do {
        let decodedData = try decoder.decode(decodingType, from: data!)
        DispatchQueue.main.async {
          completion(decodedData, nil)
        }
      } catch {
        print(error.localizedDescription)
        completion(nil, error)
      }
      
      self.fetchState = .idle
    }.resume()
  }
  
  // MARK: Deployments
  func loadDeployments() {
    self.loadDeployments { [unowned self] (entries, error) in
      if let deployments = entries {
        DispatchQueue.main.async {
          self.deployments = deployments
        }
      }
      
      if let errorMessage = error?.localizedDescription {
        print(errorMessage)
      }
    }
  }
  
  func loadDeployments(completion: @escaping ([Deployment]?, Error?) -> Void) {
    fetchState = deployments.isEmpty ? .loading : .idle
    var request = URLRequest(url: urlForRoute(.deployments, queryItems: [URLQueryItem(name: "limit", value: "100")]))
    
    request.allHTTPHeaderFields = getHeaders()
    
    fetch(request: request, decodingType: VercelAPIResponse.Deployments.self) { (deploymentsResponse, _) in
      if let deployments = deploymentsResponse?.deployments {
        DispatchQueue.main.async {
          self.deployments = deployments
        }
      }
    }
  }
  
  func loadAliases(deploymentId: String, completion: @escaping ([Alias]?, Error?) -> Void) {
    fetchState = deployments.isEmpty ? .loading : .idle
    var request = URLRequest(
      url: urlForRoute(
        .deployments,
        appending: "\(deploymentId)/aliases",
        queryItems: [URLQueryItem(name: "limit", value: "100")]
      )
    )
    
    request.allHTTPHeaderFields = getHeaders()
    
    fetch(request: request, decodingType: VercelAPIResponse.Deployments.self) { (deploymentsResponse, _) in
      if let deployments = deploymentsResponse?.deployments {
        DispatchQueue.main.async {
          self.deployments = deployments
        }
      }
    }
  }
  
  // MARK: Account
  func loadUser() {
    loadUser { (user, error) in
      if let user = user {
        self.account.user = user
      } else if let error = error {
        print(error.localizedDescription)
      }
    }
  }
  
  func loadUser(completion: @escaping (VercelUser?, Error?) -> Void) {
    var request = URLRequest(url: urlForRoute(.user))
    
    request.allHTTPHeaderFields = getHeaders()
    
    fetch(request: request, decodingType: VercelAPIResponse.User.self) { (userResponse, error) in
      if let user = userResponse?.user {
        DispatchQueue.main.async {
          completion(user, nil)
        }
      } else if let error = error {
        completion(nil, error)
      }
    }
  }
  
  func loadAccount() {
    self.loadAccount { (account, error) in
      if let error = error {
        print(error.localizedDescription)
      } else if let account = account {
        self.account = account
      }
    }
  }
  
  func loadAccount(completion: @escaping (VercelAccount?, Error?) -> Void) {
    if !account.isTeam {
      self.loadUser()
      return
    }
    
    var request = URLRequest(url: urlForRoute(.teams, appending: "\(account.id)"))
    request.allHTTPHeaderFields = getHeaders()
    
    fetch(request: request, decodingType: VercelAPIResponse.Team.self) { (accountResponse, error) in
      if let account = accountResponse {
        DispatchQueue.main.async {
          completion(account, nil)
        }
      } else if let error = error {
        completion(nil, error)
      }
    }
  }
}
