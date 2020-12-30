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

let decoder = JSONDecoder()

enum FetcherError: Error {
  case decoding, fetching, updating
}

enum VercelRoute: String {
  case teams = "v1/teams"
  case deployments = "v6/now/deployments"
  case projects = "v4/projects"
  case user = "www/user"
}

public class VercelFetcher: ObservableObject {
  enum FetchState {
    case loading
    case finished
    case error
    case idle
  }
  
  static let shared = VercelFetcher(UserDefaultsManager.shared, withTimer: true)
  
  @Published var fetchState: FetchState = .idle
  
  @Published var teams: [VercelTeam] = [] {
    didSet {
      self.loadAllDeployments()
    }
  }
  
  @Published var user: VercelUser?
  
  /**
   Since the deployments array is recycled across teams, it’s advisable to use self.deploymentsStore instead
   */
  @Published var deployments: [Deployment] = []
  
  @Published var deploymentsStore = DeploymentsStore()
  @Published var projectsStore = ProjectsStore()
  
  @ObservedObject var settings: UserDefaultsManager
  
  private var pollingTimer: Timer?
  
  init(_ settings: UserDefaultsManager) {
    self.settings = settings
  }
  
  init(_ settings: UserDefaultsManager, withTimer: Bool) {
    self.settings = settings
    self.loadUser()
    
    if withTimer {
      resetTimers()
    }
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
    if self.settings.token != nil {
      self.loadUser()
      self.loadTeams()
      self.loadAllDeployments()
      self.loadAllProjects()
    } else {
      print("Awaiting authentication token...")
    }
  }
  
  func urlForRoute(_ route: VercelRoute, query: String? = nil) -> URL {
    return URL(string: "https://api.vercel.com/\(route.rawValue)\(query ?? "")")!
  }
  
  func loadTeams() {
    self.loadTeams { [weak self] (teams, error) in
      if error != nil { print(error!) }
      
      if teams != nil {
        DispatchQueue.main.async {
          self?.teams = teams!
        }
      } else {
        print("Found `nil` instead of teams array")
      }
    }
  }
  
  func loadTeams(completion: @escaping ([VercelTeam]?, Error?) -> Void) {
    var request = URLRequest(url: urlForRoute(.teams))
    request.allHTTPHeaderFields = getHeaders()
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      do {
        guard let response = data else {
          print("Error fetching teams")
          if let fetchError = error {
            print(fetchError.localizedDescription)
          }
          return
        }
        let decodedData = try JSONDecoder().decode(VercelTeamsAPIResponse.self, from: response)
        DispatchQueue.main.async {
          completion(decodedData.teams, nil)
        }
      } catch {
        completion(nil, error)
        print("Error loading teams")
        print(error.localizedDescription)
      }
    }.resume()
  }
  
  func loadDeployments() {
    self.loadDeployments { [weak self] (entries, error) in
      if let deployments = entries {
        DispatchQueue.main.async {
          self?.deployments = deployments
        }
      }
      
      if let errorMessage = error?.localizedDescription {
        print(errorMessage)
      }
    }
  }
  
  func loadAllDeployments() {
    let personalTeam = VercelTeam()
    var teams = [personalTeam]
    teams.append(contentsOf: self.teams)
    for team in teams {
      loadDeployments(teamId: team.id) { [weak self] (entries, error) in
        if let deployments = entries {
          DispatchQueue.main.async {
            self?.deploymentsStore.updateStore(forTeam: team.id, newValue: deployments)
          }
        }
        
        if let errorMessage = error?.localizedDescription {
          print(errorMessage)
        }
      }
    }
  }
  
  func loadAllProjects() {
    let personalTeam = VercelTeam()
    var teams = [personalTeam]
    teams.append(contentsOf: self.teams)
    for team in teams {
      loadProjects(teamId: team.id) { [weak self] (entries, error) in
        if let projects = entries {
          DispatchQueue.main.async {
            self?.projectsStore.updateStore(forTeam: team.id, newValue: projects)
          }
        }
        
        if let errorMessage = error?.localizedDescription {
          print(errorMessage)
        }
      }
    }
  }
  
  func loadProjects(teamId: String? = nil, completion: @escaping ([Project]?, Error?) -> Void) {
    fetchState = deployments.isEmpty ? .loading : .idle
    let unmaskedTeamId = teamId == "-1" ? "" : teamId ?? ""
    var request = URLRequest(url: urlForRoute(.projects, query: "?teamId=\(unmaskedTeamId)"))
    
    request.allHTTPHeaderFields = getHeaders()
    
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      if let data = data {
        do {
          let response = try decoder.decode(ProjectResponse.self, from: data)
          DispatchQueue.main.async { [weak self] in
            self?.fetchState = .finished
          }
          completion(response.projects, nil)
        } catch {
          print("error: ", error)
        }
      } else {
        print("Error loading deployments")
        return
      }
    }.resume()
    
    self.objectWillChange.send()
  }
  
  func loadDeployments(teamId: String? = nil, completion: @escaping ([Deployment]?, Error?) -> Void) {
    fetchState = deployments.isEmpty ? .loading : .idle
    let unmaskedTeamId = teamId == "-1" ? "" : teamId ?? ""
    var request = URLRequest(url: urlForRoute(.deployments, query: "?teamId=\(unmaskedTeamId)&limit=100"))
    
    request.allHTTPHeaderFields = getHeaders()
    
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      if let data = data {
        do {
          let response = try decoder.decode(DeploymentResponse.self, from: data)
          DispatchQueue.main.async { [weak self] in
            self?.fetchState = .finished
          }
          completion(response.deployments, nil)
        } catch {
          print("error: ", error)
        }
      } else {
        print("Error loading deployments")
        return
      }
    }.resume()
    
    self.objectWillChange.send()
  }
  
  func loadAliases(deploymentId: String, completion: @escaping ([Alias]?, Error?) -> Void) {
    var request = URLRequest(url: urlForRoute(.deployments, query: "/\(deploymentId)/aliases"))
    
    request.allHTTPHeaderFields = getHeaders()
    
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      if let data = data {
        do {
          let response = try decoder.decode(AliasesResponse.self, from: data)
          DispatchQueue.main.async { [weak self] in
            self?.fetchState = .finished
          }
          completion(response.aliases, nil)
        } catch {
          print("error: ", error)
        }
      } else {
        print("Error loading aliases")
        return
      }
    }.resume()
  }
  
  func loadUser() {
    var request = URLRequest(url: urlForRoute(.user))
    
    request.allHTTPHeaderFields = getHeaders()
    URLSession.shared.dataTask(with: request) { [weak self] (data, _, error) in
      if data == nil {
        print("Error loading user")
        return
      }
      
      do {
        let decodedData = try JSONDecoder().decode(VercelUserAPIResponse.self, from: data!)
        DispatchQueue.main.async { [weak self] in
          self?.user = decodedData.user
        }
      } catch {
        print("Error decoding user")
        print(error.localizedDescription)
        DispatchQueue.main.async { [weak self] in
          self?.fetchState = .error
        }
      }
    }.resume()
    
    self.objectWillChange.send()
  }
  
  public func getHeaders() -> [String: String] {
    return [
      "Authorization": "Bearer " + (settings.token ?? ""),
      "Content-Type": "application/json",
      "User-Agent": "ZG Client \(APP_VERSION)"
    ]
  }
}
