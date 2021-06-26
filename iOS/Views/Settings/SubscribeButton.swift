//
//  SubscribeButton.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI
import StoreKit
import Purchases

enum PurchaseState: Equatable {
  case idle
  case purchasing(product: IAPSubscriptionType)
}

struct SubscribeButton: View {
  @ObservedObject var iapHelper = IAPHelper.shared
  @State var purchaseState: PurchaseState = .idle
  
  private var monthlySub: Purchases.Package? {
    IAPHelper.shared.monthlySubscription
  }
  
  private var yearlySub: Purchases.Package? {
    IAPHelper.shared.yearlySubscription
  }
  
  var body: some View {
    Group {
      if monthlySub == nil && yearlySub == nil {
        HStack {
          Spacer()
          ProgressView("Loading subscriptions...")
          Spacer()
        }.padding(.vertical)
      } else {
        yearlySub.map { sub in
          Button(action: {
            self.purchaseState = .purchasing(product: .annual)
            iapHelper.makeSubscriptionPurchase(package: sub) { _ in
              self.purchaseState = .idle
            }
          }) {
            HStack {
              Label("\(sub.localizedPriceString) Yearly", systemImage: "plus.square.on.square")
              
              if let priceSaving = priceSaving {
                Spacer()
                Text(priceSaving)
                  .padding(4)
                  .padding(.horizontal, 4)
                  .background(Color.systemPink)
                  .cornerRadius(4)
                  .font(.footnote.bold())
                  .foregroundColor(.white)
              }
            }
          }
          .opacity(self.purchaseState == .purchasing(product: .annual) ? 0.5 : 1)
          .disabled(self.purchaseState != .idle)
        }
        
        monthlySub.map { sub in
          Button(action: {
            self.purchaseState = .purchasing(product: .monthly)
            iapHelper.makeSubscriptionPurchase(package: sub) { _ in
              self.purchaseState = .idle
            }
          }) {
            Label("\(sub.localizedPriceString) Monthly", systemImage: "plus.app")
          }
          .opacity(self.purchaseState == .purchasing(product: .monthly) ? 0.5 : 1)
          .disabled(self.purchaseState != .idle)
        }
        
      }
      
      #if !os(macOS)
      Button(action: { SKPaymentQueue.default().presentCodeRedemptionSheet() }, label: {
        Label("Redeem Offer Code", systemImage: "tag")
      })
      
      Button(action: {
        self.purchaseState = .purchasing(product: .other)
        iapHelper.restorePurchases { _ in
          self.purchaseState = .idle
        }
      }, label: {
        Label("Restore Purchases", systemImage: "purchased")
      })
      #endif
    }.symbolRenderingMode(.hierarchical)
  }
  
  private var priceSaving: LocalizedStringKey? {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    
    guard let monthlySub = monthlySub,
          let yearlySub = yearlySub else {
      return nil
    }
    
    let savings = (monthlySub.product.price.doubleValue * 12) - yearlySub.product.price.doubleValue
    
    return "\(formatter.string(from: NSNumber(value: savings))!) off"
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
