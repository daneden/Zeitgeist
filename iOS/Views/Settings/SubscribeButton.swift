//
//  SubscribeButton.swift
//  iOS
//
//  Created by Daniel Eden on 19/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import SwiftUI
import StoreKit

enum PurchaseState: Equatable {
  case idle
  case purchasing(product: IAPSubscriptionType)
}

struct SubscribeButton: View {
  @ObservedObject var iapHelper = IAPHelper.shared
  @State var purchaseState: PurchaseState = .idle
  
  var body: some View {
    ForEach(iapHelper.subscriptionProducts, id: \.productIdentifier) { product in
      if let productType = IAPSubscriptionType(rawValue: product.productIdentifier) {
        Button(action: {
          self.purchaseState = .purchasing(product: productType)
          
          iapHelper.makeSubscriptionPurchase(type: productType) { _ in
            self.purchaseState = .idle
          }
        }, label: {
          HStack {
            Text("\(product.localizedTitle) (\(formattedPriceForProduct(product)))")
            
            Spacer()
            
            if case .purchasing(let value) = purchaseState,
               value == productType {
              ProgressView()
            } else if productType == .annual {
              SavingsBadge()
            }
          }
        })
        .disabled(purchaseState != .idle)
      }
    }
  }
  
  func formattedPriceForProduct(_ product: SKProduct) -> String {
    let price = product.price
    let locale = product.priceLocale
    
    let formatter = NumberFormatter()
    formatter.locale = locale
    formatter.numberStyle = .currency
    
    return formatter.string(from: price)!
  }
}

struct SubscribeButton_Previews: PreviewProvider {
  static var previews: some View {
    SubscribeButton()
  }
}

struct SavingsBadge: View {
  var body: some View {
    Text("2 Months Free")
      .padding(4)
      .padding(.horizontal, 2)
      .background(Color.systemPink)
      .font(Font.caption.weight(.bold))
      .foregroundColor(.white)
      .cornerRadius(8, antialiased: true)
  }
}
