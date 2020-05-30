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
  
  weak var timer: Timer? {
    willSet {
      timer?.invalidate()
    }
  }
  
  var prefs = UserDefaultsManager()

  init(with network: Network) {
    self.network = network
  }
  
  func fetch(route: NetworkRoute, append: String?) {
    (network.fetch(route: route, append: append) as AnyPublisher<NetworkResource, Error>)
      .receive(on: RunLoop.current)
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
    // Initial render
    fetchUpdate()
    
    self.timer?.invalidate()
    self.timer = nil
    
    let fetchPeriod = Double(max(self.prefs.fetchPeriod ?? 3, 3))
    self.timer = Timer.scheduledTimer(timeInterval: fetchPeriod, target: self, selector: #selector(onTimerTick), userInfo: "Tick: ", repeats: true)
    self.timer?.tolerance = fetchPeriod * 0.1
  }
  
  @objc func onTimerTick(timer: Timer) {
    fetchUpdate()
  }
  
  func fetchUpdate() {
    let currentTeam = self.prefs.currentTeam
    let appendage = (currentTeam == nil || currentTeam == "0") ? nil : "?teamId=\(currentTeam!)"
    self.fetch(route: self.route, append: appendage)
  }
}
