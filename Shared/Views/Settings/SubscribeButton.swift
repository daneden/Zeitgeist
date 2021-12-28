//
//  SubscribeButton.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI
import StoreKit
import StoreKit

enum PurchaseState: Equatable {
  case idle
  case purchasing(productID: String? = nil)
}

struct SubscribeButton: View {
  @ObservedObject var iapHelper = IAPHelper.shared
  
  @State var products: [Product] = []
  @State var latestTransaction: StoreKit.Transaction?
  @State var purchaseState = PurchaseState.idle
  
  var body: some View {
    Group {
      if products.isEmpty {
        HStack {
          Spacer()
          ProgressView("Loading subscriptions...")
          Spacer()
        }.padding(.vertical)
      } else {
        ForEach(products) { product in
          Button(action: {
            Task {
              self.latestTransaction = try await self.purchaseProduct(product)
            }
          }) {
            HStack {
              Text(product.displayName)
              Spacer()
              if self.purchaseState == .purchasing(productID: product.id) {
                ProgressView()
              } else {
                Text(product.displayPrice).foregroundStyle(.secondary)
              }
            }
          }
          .opacity(self.purchaseState == .purchasing(productID: product.id) ? 0.5 : 1)
        }
      }
      
      #if !os(macOS)
      Button(action: { SKPaymentQueue.default().presentCodeRedemptionSheet() }, label: {
        Label("Redeem Offer Code", systemImage: "tag")
      })
      
      Button(action: {
        self.purchaseState = .purchasing(productID: nil)
        Task {
          await iapHelper.restorePurchases()
          self.purchaseState = .idle
        }
      }, label: {
        Label("Restore Purchases", systemImage: "purchased")
      })
      #endif
    }
    .disabled(self.purchaseState != .idle)
    .symbolRenderingMode(.hierarchical)
    .task {
      await fetchProducts()
    }
  }
  
  func fetchProducts() async {
    do {
      self.products = try await Product.products(for: supporterProductIds)
    } catch {
      print("Unable to fetch products")
    }
  }
  
  func purchaseProduct(_ product: Product) async throws -> StoreKit.Transaction {
    purchaseState = .purchasing(productID: product.id)
    
    let result = try await product.purchase()
    
    purchaseState = .idle
    
    switch result {
    case .pending:
      throw PurchaseError.pending
    case .success(let verification):
      switch verification {
      case .verified(let transaction):
        await transaction.finish()
        
        return transaction
      case .unverified:
        throw PurchaseError.failed
      }
    case .userCancelled:
      throw PurchaseError.cancelled
    @unknown default:
      assertionFailure("Unexpected result")
      throw PurchaseError.failed
    }
  }
}

enum PurchaseError: Error {
  case pending, failed, cancelled
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
