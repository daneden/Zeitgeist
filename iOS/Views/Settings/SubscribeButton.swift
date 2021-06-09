//
//  SubscribeButton.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
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
    Group {
      ForEach(iapHelper.subscriptionProducts, id: \.productIdentifier) { product in
        if let productType = IAPSubscriptionType(rawValue: product.productIdentifier) {
          Button(action: {
            self.purchaseState = .purchasing(product: productType)
            
            iapHelper.makeSubscriptionPurchase(type: productType) { _ in
              self.purchaseState = .idle
            }
          }, label: {
            HStack {
              Text("\(product.localizedTitle) (\(product.localizedPrice))")
              
              Spacer()
              
              if case .purchasing(let value) = purchaseState,
                 value == productType {
                ProgressView()
              }
            }
          })
          .disabled(purchaseState != .idle)
        }
      }
      
      Button(action: { SKPaymentQueue.default().presentCodeRedemptionSheet() }, label: {
        Label("Redeem Offer Code", systemImage: "tag")
      })
      
      Link(destination: URL(string: "https://zeitgeist.daneden.me/privacy")!) {
        Text("Privacy Policy")
      }
      
      Link(destination: URL(string: "https://zeitgeist.daneden.me/terms")!) {
        Text("Terms of Use")
      }
    }
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
