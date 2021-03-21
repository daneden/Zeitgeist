//
//  IAPHelper.swift
//  iOS
//
//  Created by Daniel Eden on 20/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation
import Combine
import Purchases
import SwiftUI

enum IAPSubscriptionType: String, CaseIterable {
  case monthly = "me.daneden.Zeitgeist.IAPSupporter"
  case annual = "me.daneden.Zeitgeist.IAPSupporter.annual"
}

class IAPHelper: ObservableObject {
  @AppStorage(UDValues.activeSupporterSubscription) private var activeSubscriber
  
  @Published var subscriptionProducts = [SKProduct]()
  
  static var shared = IAPHelper()
  
  init() {
    self.refresh()
  }
  
  func makeSubscriptionPurchase(type: IAPSubscriptionType, completion: @escaping (_ wasSuccessful: Bool) -> Void) {
    PurchaseService.purchase(productID: type.rawValue) { wasSuccessful in
      self.activeSubscriber = wasSuccessful
      completion(wasSuccessful)
    }
  }
  
  func refresh() {
    // Check if the user has an active subscription
    Purchases.shared.purchaserInfo { (info, error) in
      // Check user info for active entitlements
      if let error = error {
        print(error.localizedDescription)
      }
      
      self.activeSubscriber = info?.entitlements["supporter"]?.isActive == true
    }
    
    Purchases.shared.products(IAPSubscriptionType.allCases.map { $0.rawValue }) { (products) in
      self.subscriptionProducts = products
    }
  }
}

class PurchaseService {
  static func purchase(productID: String?, completion: @escaping (_ successful: Bool) -> Void) {
    guard productID != nil else {
      return
    }
    
    var skProduct: SKProduct?
    
    Purchases.shared.products([productID!]) { products in
      if !products.isEmpty {
        skProduct = products.first
        
        Purchases.shared.purchaseProduct(skProduct!) { (transaction, purchaseInfo, error, userCancelled) in
          if let error = error {
            print(error.localizedDescription)
            completion(false)
            return
          }
          
          if error == nil && !userCancelled {
            completion(true)
          } else if userCancelled {
            completion(false)
          }
          
          print(purchaseInfo as Any)
          print(transaction as Any)
        }
      }
    }
  }
}
