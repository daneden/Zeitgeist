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

enum FetchState {
  case loading
  case finished
  case error
  case idle
}

struct VercelTeam: Decodable {
  public var id: String
  public var name: String
}

struct VercelTeamsAPIResponse: Decodable {
  public var teams: [VercelTeam] = [VercelTeam]()
}

enum VercelRoute: String {
  case teams = "v1/teams"
  case deployments = "v6/now/deployments"
}

public class VercelFetcher: ObservableObject {
  @Published var fetchState: FetchState = .idle
  @Published var teams = [VercelTeam]()
  @Published var deployments = [VercelDeployment]()
  @ObservedObject var settings: UserDefaultsManager
  
  var teamId: String? {
    didSet {
      self.fetchState = .loading
      self.deployments = [VercelDeployment]()
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
          self.objectWillChange.send()
        }
      } catch {
        print("Error loading teams")
        print(error.localizedDescription)
      }
    }.resume()
  }
  
  func loadDeployments() {
    fetchState = deployments.isEmpty ? .loading : .idle
    var request: URLRequest
    
    if self.teamId != nil {
      request = URLRequest(url: urlForRoute(.deployments, query: "?teamId=\(self.teamId!)"))
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
          print(request)
          self.deployments = decodedData.deployments
          self.fetchState = .finished
        }
      } catch {
        print("Error loading deployments")
        print(error.localizedDescription)
        self.fetchState = .error
      }
    }.resume()
    
    self.objectWillChange.send()
  }
  
  public func getHeaders() -> [String: String] {
    return [
      "Authorization": "Bearer " + (settings.token ?? ""),
      "Content-Type": "application/json",
      "User-Agent": "Zeitgeist Client \(APP_VERSION)"
    ]
  }
}