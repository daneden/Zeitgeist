//
//  ZeitDeploymentsViewModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine

class VercelViewModel: NetworkViewModel, ObservableObject {
  var resource: Resource<ZeitDeploymentsArray> = .loading
  var network: Network

  var route: NetworkRoute = VercelNetworkRoute.deployments

  var bag: Set<AnyCancellable> = Set<AnyCancellable>()
  var cancellable: AnyCancellable?

  init(with network: Network) {
    self.network = network
  }
  
  func fetch(route: NetworkRoute, append: String?) {
    (network.fetch(route: route, append: append) as AnyPublisher<NetworkResource, Error>)
      .receive(on: RunLoop.main)
      .sink(receiveCompletion: { completion in
        switch completion {
        case .failure(let error):
          self.resource = .error(error)
          self.objectWillChange.send()
        default:
          break
        }
      }, receiveValue: { decodable in
        self.resource = .success(decodable)
        self.objectWillChange.send()
      })
      .store(in: &bag)
  }
  
  func onAppear() {
    let prefs = UserDefaultsManager()
    
    let fetchPeriod = max(prefs.fetchPeriod ?? 3, 3)
    let currentTeam = prefs.currentTeam
    let appendage = (currentTeam == nil || currentTeam == "0") ? nil : "?teamId=\(currentTeam!)"
    fetch(route: route, append: appendage)
    
    Timer.scheduledTimer(withTimeInterval: Double(fetchPeriod), repeats: true) { timer in
      if currentTeam != UserDefaultsManager().currentTeam {
        timer.invalidate()
        self.objectWillChange.send()
        self.onAppear()
      }
    }
  }
}
