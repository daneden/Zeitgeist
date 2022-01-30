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
  static let supporterProductIds: Set<String> = [
    "me.daneden.Zeitgeist.IAPSupporter.annual",
    "me.daneden.Zeitgeist.IAPSupporter"
  ]

  @AppStorage("activeSupporterSubscription") private(set) var activeSubscriber = false
  
  static var shared = IAPHelper()
  
  init() {
    Task {
      await self.restorePurchases()
    }
  }
  
  @MainActor
  @discardableResult
  func restorePurchases() async -> Int {
    var verifiedPurchases = 0
    for await verificationResult in Transaction.currentEntitlements {
      if case .verified(let transaction) = verificationResult {
        verifiedPurchases += 1
        activeSubscriber = (IAPHelper.supporterProductIds.contains(transaction.productID))
        if !activeSubscriber {
          NotificationManager.shared.toggleNotifications(on: false)
        }
      }
    }
    
    return verifiedPurchases
  }
}
