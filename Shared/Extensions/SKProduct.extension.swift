//
//  SKProduct.extension.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation
import StoreKit

extension SKProduct {
  var localizedPrice: String {
    let formatter = NumberFormatter()
    formatter.locale = priceLocale
    formatter.numberStyle = .currency
    
    return formatter.string(from: price)!
  }
}
