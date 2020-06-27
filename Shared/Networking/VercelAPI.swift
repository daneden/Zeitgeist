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
  
  init(_ settings: UserDefaultsManager) {
    self.settings = settings
    
  }
  
  func urlForRoute(_ route: VercelRoute) -> URL {
    return URL(string: "https://api.vercel.com/\(route.rawValue)")!
  }
  
  func loadTeams() {
    fetchState = .loading
    var request = URLRequest(url: urlForRoute(.teams))
    request.allHTTPHeaderFields = getHeaders()
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      do {
        let decodedData = try JSONDecoder().decode(VercelTeamsAPIResponse.self, from: data!)
        DispatchQueue.main.async {
          self.teams = decodedData.teams
          self.fetchState = .finished
        }
      } catch {
        print("Error loading teams")
        print(error.localizedDescription)
        self.fetchState = .error
      }
    }.resume()
    
    self.objectWillChange.send()
  }
  
  func loadDeployments() {
    fetchState = .loading
    var request = URLRequest(url: urlForRoute(.deployments))
    request.allHTTPHeaderFields = getHeaders()
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      do {
        let decodedData = try JSONDecoder().decode(VercelDeploymentsAPIResponse.self, from: data!)
        DispatchQueue.main.async {
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
