//
//  IAPHelper.swift
//  iOS
//
//  Created by Daniel Eden on 19/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import StoreKit
import Combine
import SwiftUI

enum TransactionType {
  case purchase, restore
}

enum IAPProduct: String, CaseIterable {
  case supporter = "me.daneden.Zeitgeist.IAPSupporter"
}

let purchasePublisher = PassthroughSubject<(String, TransactionType, Bool, Bool), Never>()
var totalRestoredPurchases = 0

class IAPHelper: NSObject, ObservableObject {
  static let shared = IAPHelper()
  private let prefs = Preferences.shared.store
  
  var purchasedItems: [String] {
    get {
      return prefs.stringArray(forKey: "purchasedProductIDs") ?? []
    }
    
    set {
      prefs.set(newValue.unique(), forKey: "purchasedProductIDs")
      prefs.synchronize()
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    }
  }
  
  private override init() {
    super.init()
  }
  
  func hasPurchased(productId: IAPProduct) -> Bool {
    // Always enable IAP features in TestFlight and debugging
    if Config.appConfiguration == .TestFlight || Config.appConfiguration == .Debug {
      return true
    }
    
    return self.purchasedItems.contains(productId.rawValue)
  }
  
  func returnProductIDs() -> [String] {
    return IAPProduct.allCases.map { (productId) -> String in
      productId.rawValue
    }
  }
  
  func canMakePayments() -> Bool {
    // Always enable IAP features in TestFlight and debugging
    if Config.appConfiguration == .TestFlight || Config.appConfiguration == .Debug {
      return true
    }
    
    return SKPaymentQueue.canMakePayments()
  }
  
  func getProducts() {
    let productIDs = Set(returnProductIDs())
    let request = SKProductsRequest(productIdentifiers: Set(productIDs))
    request.delegate = self
    request.start()
  }
  
  func getPriceFormatted(for product: SKProduct) -> String? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = product.priceLocale
    return formatter.string(from: product.price)
  }
  
  func startObserving() {
    SKPaymentQueue.default().add(self)
  }
  
  func stopObserving() {
    SKPaymentQueue.default().remove(self)
  }
  
  func purchase(product: SKProduct) -> Bool {
    if !IAPHelper.shared.canMakePayments() {
      return false
    } else {
      let payment = SKPayment(product: product)
      SKPaymentQueue.default().add(payment)
    }
    return true
  }
  
  func restorePurchases() {
    totalRestoredPurchases = 0
    SKPaymentQueue.default().restoreCompletedTransactions()
  }
}

extension IAPHelper: SKProductsRequestDelegate, SKRequestDelegate {
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    let badProducts = response.invalidProductIdentifiers
    let goodProducts = response.products
    if !goodProducts.isEmpty {
      ProductsDB.shared.items = response.products
    }
    
    if !badProducts.isEmpty {
      print("Encountered \(badProducts.count) invalid IDs ", badProducts)
    }
  }
}

final class ProductsDB: ObservableObject, Identifiable {
  static let shared = ProductsDB()
  var items: [SKProduct] = [] {
    willSet {
      DispatchQueue.main.async {
        self.objectWillChange.send()
      }
    }
  }
}

extension IAPHelper: SKPaymentTransactionObserver {
  func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    if totalRestoredPurchases != 0 {
      purchasePublisher.send(("Purchases successfully restored", .restore, true, true))
      print("Purchases restored")
    } else {
      purchasePublisher.send(("No purchases to restore", .restore, true, true))
      print("No purchases restored")
    }
    
    DispatchQueue.main.async {
      self.objectWillChange.send()
    }
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
    if !IAPHelper.shared.canMakePayments() {
      return false
    } else {
      SKPaymentQueue.default().add(payment)
    }
    
    return true
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    transactions.forEach { (transaction) in
      switch transaction.transactionState {
      case .purchased:
        SKPaymentQueue.default().finishTransaction(transaction)
        purchasePublisher.send(("Purchased ", .purchase, true, true))
        purchasedItems.append(transaction.payment.productIdentifier)
        
      case .restored:
        totalRestoredPurchases += 1
        SKPaymentQueue.default().finishTransaction(transaction)
        purchasePublisher.send(("Restored ", .restore, true, true))
        if let id = transaction.original?.payment.productIdentifier {
          purchasedItems.append(id)
        }
      case .failed:
        if let error = transaction.error as? SKError {
          purchasePublisher.send(("Payment Error \(error.code) ", .purchase, false, true))
          print("Payment Failed \(error.code)")
        }
        SKPaymentQueue.default().finishTransaction(transaction)
      case .deferred:
        print("Payment Deferred")
        purchasePublisher.send(("Payment Deferred ", .purchase, false, true))
      case .purchasing:
        print("Purchasing...")
        purchasePublisher.send(("Payment in Process ", .purchase, false, false))
      default:
        break
      }
    }
    
    DispatchQueue.main.async {
      self.objectWillChange.send()
    }
  }
}
