//
//  PurchaseManager.swift
//  iOS
//
//  Created by Daniel Eden on 02/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI
import Purchases

public class PurchaseManager: ObservableObject {
  public static let shared = PurchaseManager()
  let userDefaults = UserDefaultsManager()
  
  public enum SubscriptionStatus {
    case subscribed, notSubscribed
  }
    
  @Published public var tipPurchase: Purchases.Package?
  @Published public var supporterSubscription: Purchases.Package?
  @Published public var inPaymentProgress = false
  @Published public var subscriptionStatus: SubscriptionStatus = UserDefaultsManager().isSubscribed ?? false ? .subscribed : .notSubscribed
    
  init() {
    Purchases.configure(withAPIKey: "BtsJTlCfcJkRXMbWTTraNErvIsCcLkLb")
    Purchases.shared.offerings { (offerings, error) in
        self.supporterSubscription = offerings?.current?.monthly
        self.tipPurchase = offerings?.current?.lifetime
    }
    refreshSubscription()
  }
    
  public func purchase(source: String, product: Purchases.Package) {
    guard !inPaymentProgress else { return }
    inPaymentProgress = true
    Purchases.shared.setAttributes(["source": source])
    Purchases.shared.purchasePackage(product) { (_, info, _, _) in
      self.processInfo(info: info)
    }
  }
    
    
  public func refreshSubscription() {
    Purchases.shared.purchaserInfo { (info, _) in
      self.processInfo(info: info)
    }
  }
    
  public func restorePurchase() {
    Purchases.shared.restoreTransactions { (info, _) in
      self.processInfo(info: info)
    }
  }
    
    private func processInfo(info: Purchases.PurchaserInfo?) {
        if info?.entitlements.all["AC+"]?.isActive == true {
            subscriptionStatus = .subscribed
            userDefaults.isSubscribed = true
        } else {
            userDefaults.isSubscribed = false
            subscriptionStatus = .notSubscribed
        }
        inPaymentProgress = false
    }
}
