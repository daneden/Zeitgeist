//
//  SubscribeButton.swift
//  iOS
//
//  Created by Daniel Eden on 19/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import SwiftUI
import StoreKit

struct SubscribeButton: View {
  @Binding var purchased: Bool
  @ObservedObject var products = ProductsDB.shared
  @State var isPurchasing = false
  @State var isRestoring = false
  
  var body: some View {
    ForEach((0 ..< self.products.items.count), id: \.self) { column in
      if let product = self.products.items[column],
         let price = IAPHelper.shared.getPriceFormatted(for: product) {
        Button(action: {
          purchaseItem(product: product)
        }, label: {
          HStack(spacing: 8) {
            Label("Buy \(product.localizedTitle) for \(price)", systemImage: "app.gift")
            Spacer()
            if isPurchasing { ProgressView().colorScheme(.light) }
          }
        })
        .buttonStyle(BorderlessButtonStyle())
        .disabled(isPurchasing)
      }
    }
    
    Button(action: restorePurchases) {
      HStack(spacing: 8) {
        Text("Restore Purchases")
        Spacer()
        if isRestoring { ProgressView() }
      }
      .padding()
    }
    .disabled(isRestoring)
    .onReceive(purchasePublisher) { (_, _, _, complete) in
      if self.isPurchasing {
        self.isPurchasing = !complete
        if complete {
          isPurchasing = false
        }
      } else if self.isRestoring {
        self.isRestoring = !complete
        if complete {
          isRestoring = false
        }
      }
    }
  }
  
  func restorePurchases() {
    IAPHelper.shared.restorePurchases()
    self.isRestoring = true
  }
  
  func purchaseItem(product: SKProduct) {
    _ = IAPHelper.shared.purchase(product: product)
    self.isPurchasing = true
  }
}

struct SubscribeButton_Previews: PreviewProvider {
  static var previews: some View {
    SubscribeButton(purchased: .constant(false))
  }
}
