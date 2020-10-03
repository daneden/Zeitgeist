//
//  VercelAPI.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/06/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine
import SwiftUI

var APP_VERSION: String = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"

enum FetchState {
  case loading
  case finished
  case error
  case idle
}

struct VercelTeamsAPIResponse: Decodable {
  public var teams: [VercelTeam] = [VercelTeam]()
}

enum VercelRoute: String {
  case teams = "v1/teams"
  case deployments = "v6/now/deployments"
  case user = "www/user"
}

public class VercelFetcher: ObservableObject {
  static let shared = VercelFetcher(UserDefaultsManager.shared)
  
  @Published var fetchState: FetchState = .idle {
    didSet {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    }
  }
  
  @Published var teams = [VercelTeam]() {
    didSet {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    }
  }
  
  @Published var deployments = [VercelDeployment]() {
    didSet {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    }
  }
  
  @Published var user: VercelUser? {
    didSet {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    }
  }
  
  @ObservedObject var settings: UserDefaultsManager
  
  var teamId: String? {
    didSet {
      self.fetchState = .loading
      self.deployments = []
      self.loadDeployments()
      self.objectWillChange.send()
    }
  }
  
  private var deploymentsTimer: Timer?
  private var teamsTimer: Timer?
  
  init(_ settings: UserDefaultsManager) {
    self.settings = settings
  }
  
  init(_ settings: UserDefaultsManager, withTimer: Bool) {
    self.settings = settings
    self.loadUser()
    if withTimer {
      deploymentsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { time in
        self.loadDeployments()
      })
      
      teamsTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true, block: { time in
        self.loadTeams()
      })
      
      deploymentsTimer?.tolerance = 1
      teamsTimer?.tolerance = 1
    }
  }
  
  deinit {
    deployments = [VercelDeployment]()
    deploymentsTimer?.invalidate()
    deploymentsTimer = nil
    
    teams = [VercelTeam]()
    teamsTimer?.invalidate()
    teamsTimer = nil
  }
  
  func urlForRoute(_ route: VercelRoute, query: String? = nil) -> URL {
    return URL(string: "https://api.vercel.com/\(route.rawValue)\(query ?? "")")!
  }
  
  func loadTeams() {
    var request = URLRequest(url: urlForRoute(.teams))
    request.allHTTPHeaderFields = getHeaders()
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      do {
        let decodedData = try JSONDecoder().decode(VercelTeamsAPIResponse.self, from: data!)
        DispatchQueue.main.async {
          self.teams = decodedData.teams
        }
      } catch {
        print("Error loading teams")
        print(error.localizedDescription)
      }
    }.resume()
  }
  
  func loadDeployments() {
    self.loadDeployments { (entries, error) in
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
  
  func loadDeployments(completion: @escaping ([VercelDeployment]?, Error?) -> Void) {
    fetchState = deployments.isEmpty ? .loading : .idle
    var request: URLRequest
    
    if let teamId = getTeamId() {
      request = URLRequest(url: urlForRoute(.deployments, query: "?teamId=\(teamId)"))
    } else {
      request = URLRequest(url: urlForRoute(.deployments))
    }
    
    request.allHTTPHeaderFields = getHeaders()
    
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      if(data == nil) {
        print("Error loading deployments")
        return
      }
      
      do {
        let decodedData = try JSONDecoder().decode(VercelDeploymentsAPIResponse.self, from: data!)
        DispatchQueue.main.async {
          self.deployments = decodedData.deployments
          self.fetchState = .finished
        }
        completion(decodedData.deployments, nil)
      } catch {
        print("Error decoding deployments")
        print(error.localizedDescription)
        DispatchQueue.main.async {
          self.fetchState = .error
        }
        completion(nil, error)
      }
    }.resume()
    
    self.objectWillChange.send()
  }
  
  func loadUser() {
    var request = URLRequest(url: urlForRoute(.user))
    
    request.allHTTPHeaderFields = getHeaders()
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      if(data == nil) {
        print("Error loading user")
        return
      }
      
      do {
        let decodedData = try JSONDecoder().decode(VercelUserAPIResponse.self, from: data!)
        DispatchQueue.main.async {
          self.user = decodedData.user
        }
      } catch {
        print("Error decoding user")
        print(error.localizedDescription)
        DispatchQueue.main.async {
          self.fetchState = .error
        }
      }
    }.resume()
    
    self.objectWillChange.send()
  }
  
  func getTeamId() -> String? {
    return self.settings.currentTeam
  }
  
  public func getHeaders() -> [String: String] {
    return [
      "Authorization": "Bearer " + (settings.token ?? ""),
      "Content-Type": "application/json",
      "User-Agent": "ZG Client \(APP_VERSION)"
    ]
  }
}
