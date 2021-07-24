//
//  StateManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 24/07/2021.
//

import Foundation
import Combine

class StateManager: ObservableObject {
  @Published var accountId: Account.ID? = Session.shared.accountId
  @Published var deploymentId: Deployment.ID?
}
