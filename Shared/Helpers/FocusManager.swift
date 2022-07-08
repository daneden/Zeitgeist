//
//  FocusManager.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/01/2022.
//

import Foundation
import Combine

enum FocusSubject {
  case deployment(_ deployment: Deployment, account: Account.ID)
  case account(id: Account.ID)
}

enum FocusSubjectAction: Equatable {
  case delete(_ deployment: Deployment)
  case cancel(_ deployment: Deployment)
}

class FocusManager: ObservableObject {
  @Published var focusedElement: FocusSubject?
  @Published var action: FocusSubjectAction?
}
