//
//  IAPHelper.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Combine
import StoreKit
import SwiftUI

class IAPHelper: ObservableObject {
  @AppStorage("activeSupporterSubscription") private(set) var activeSubscriber = false
  
  static var shared = IAPHelper()
  
  init() {
    Task {
      await self.restorePurchases()
    }
  }
  
  func restorePurchases() async {
    for await verificationResult in Transaction.currentEntitlements {
      if case .verified(let transaction) = verificationResult {
        activeSubscriber = (supporterProductIds.contains(transaction.productID))
      }
    }
  }
}
