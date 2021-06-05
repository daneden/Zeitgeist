//
//  SubscriptionView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SubscriptionView: View {
  @AppStorage("activeSupporterSubscription") var activeSubscription = false
  @ObservedObject var iapHelper = IAPHelper.shared
  
  var body: some View {
    Form {
      if activeSubscription {
        Section(header: Label("Supporter Subscription", systemImage: "heart")) {
          ForEach(iapHelper.activeSubscriptions, id: \.productIdentifier) { product in
            VStack(alignment: .leading) {
              Text("Current Subscription")
                .font(.caption)
                .foregroundColor(.secondary)
              
              HStack {
                Text(product.localizedTitle)
                
                Spacer()
                
                Text(product.localizedPrice)
                  .foregroundColor(.secondary)
              }
            }
          }
          Button(action: { UIApplication.openSubscriptionManagement() }, label: {
            Text("Manage in App Store")
          })
        }
      } else {
        SupporterPromoView()
      }
    }
  }
}

struct SubscriptionView_Previews: PreviewProvider {
  static var previews: some View {
    SubscriptionView()
  }
}
