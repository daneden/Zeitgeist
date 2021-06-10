//
//  IAPHelper.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Combine
import Purchases
import SwiftUI

enum IAPSubscriptionType: String, CaseIterable {
  case monthly = "me.daneden.Zeitgeist.IAPSupporter"
  case annual = "me.daneden.Zeitgeist.IAPSupporter.annual"
}

class IAPHelper: ObservableObject {
  @AppStorage("activeSupporterSubscription") private(set) var activeSubscriber = false
  
  @Published var activeSubscriptions = [SKProduct]()
  
  @Published var monthlySubscription: Purchases.Package?
  @Published var yearlySubscription: Purchases.Package?
  
  static var shared = IAPHelper()
  
  init() {
    self.refresh()
  }
  
  func makeSubscriptionPurchase(package: Purchases.Package, completion: @escaping (_ wasSucessful: Bool) -> Void) {
    PurchaseService.purchase(package: package) { wasSuccessful in
      self.activeSubscriber = wasSuccessful
      completion(wasSuccessful)
    }
  }
  
  func refresh() {
    Purchases.shared.offerings { (offerings, error) in
      self.monthlySubscription = offerings?.current?.monthly
      self.yearlySubscription = offerings?.current?.annual
    }
    
    Purchases.shared.purchaserInfo { (info, error) in
      // Check user info for active entitlements
      if let error = error {
        print(error.localizedDescription)
      }
      
      self.activeSubscriber = info?.entitlements["supporter"]?.isActive == true
    }
  }
}

class PurchaseService {
  static func purchase(package: Purchases.Package, completion: @escaping (_ successful: Bool) -> Void) {
    Purchases.shared.purchasePackage(package) { (transation, purchaseInfo, error, userCancelled) in
      if let error = error {
        print(error)
        print(error.localizedDescription)
        completion(false)
        return
      }
      
      if error == nil && !userCancelled {
        completion(true)
      } else if userCancelled {
        completion(false)
      }
    }
  }
}
