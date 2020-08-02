//
//  PurchaseView.swift
//  iOS
//
//  Created by Daniel Eden on 02/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

import Purchases

struct PurchaseView: View {
  enum Source: String {
    case settings
  }
  
  @EnvironmentObject private var subscriptionManager: PurchaseManager
  @Environment(\.presentationMode) private var presentationMode
  
  let source: Source
  @State private var sheetURL: URL?
  
  var body: some View {
    paymentButtons
  }
  
  private var sub: Purchases.Package? {
    subscriptionManager.supporterSubscription
  }
  
  private var oneoffTip: Purchases.Package? {
    subscriptionManager.tipPurchase
  }
  
  private func formattedPrice(for package: Purchases.Package) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = sub!.product.priceLocale
    return formatter.string(from: package.product.price)!
  }
  
  private var paymentButtons: some View {
    VStack {
      HStack(spacing: 0) {
        sub.map{ sub in
          makeBorderedButton(action: {
            self.buttonAction(purchase: sub)
          }, label: self.subscriptionManager.subscriptionStatus == .subscribed ?
            "Thanks!" :
            "\(formattedPrice(for: sub)) Monthly")
          .opacity(subscriptionManager.inPaymentProgress ? 0.5 : 1.0)
          .disabled(subscriptionManager.inPaymentProgress)
        }
        
        Spacer(minLength: 18)
      }.frame(maxWidth: 320)
      
      oneoffTip.map{ lifetime in
        makeBorderedButton(action: {
          self.buttonAction(purchase: lifetime)
        }, label: self.subscriptionManager.subscriptionStatus == .subscribed ?
          "Thank you for your support!" :
          "Buy lifetime AC Helper+ for \(formattedPrice(for: lifetime))")
        .opacity(subscriptionManager.inPaymentProgress ? 0.5 : 1.0)
        .disabled(subscriptionManager.inPaymentProgress)
        .padding(.top, 16)
      }.frame(maxWidth: 320)
    }
  }
  
  private func buttonAction(purchase: Purchases.Package) {
    if subscriptionManager.subscriptionStatus == .subscribed {
      presentationMode.wrappedValue.dismiss()
    } else {
      subscriptionManager.purchase(source: self.source.rawValue,
                                   product: purchase)
    }
  }
  
  private func makeBorderedButton(action: @escaping () -> Void, label:
                                    LocalizedStringKey) -> some View {
    Button(action: action) {
      Text(label)
        .font(.headline)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .minimumScaleFactor(0.01)
        .lineLimit(1)
        .frame(maxWidth: .infinity,
               maxHeight: 30)
    }
  }
}
