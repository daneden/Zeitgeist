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
  @AppStorage("activeSupporterSubscription") private var activeSubscriber = false
  
  @Published var activeSubscriptions = [SKProduct]()
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
    Purchases.shared.products(IAPSubscriptionType.allCases.map { $0.rawValue }) { (products) in
      self.subscriptionProducts = products
    }
    
    Purchases.shared.purchaserInfo { (info, error) in
      // Check user info for active entitlements
      if let error = error {
        print(error.localizedDescription)
      }
      
      self.activeSubscriber = info?.entitlements["supporter"]?.isActive == true
      
      guard let activeSubscriptions = info?.activeSubscriptions.map { id in
        self.subscriptionProducts.first { $0.productIdentifier == id }
      }.filter({ product in
        product != nil
      }) as? [SKProduct] else {
        return
      }
      
      self.activeSubscriptions = activeSubscriptions
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
          
          print(purchaseInfo as Any)
          print(transaction as Any)
        }
      }
    }
  }
}
