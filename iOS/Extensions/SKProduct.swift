//
//  SKProduct.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import StoreKit

extension SKProduct {
  var localizedPrice: String {
    let formatter = NumberFormatter()
    formatter.locale = priceLocale
    formatter.numberStyle = .currency
    
    return formatter.string(from: price)!
  }
}
