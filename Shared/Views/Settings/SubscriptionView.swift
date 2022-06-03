//
//  SubscriptionView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SubscriptionView: View {
  @ObservedObject var iapHelper = IAPHelper.shared
  
  var body: some View {
    Form {
      if iapHelper.activeSubscriber {
        Section(header: Label("Supporter Subscription", systemImage: "heart"), footer: TermsAndPrivacyView()) {
          HStack {
            Text("Subscription Status")
            Spacer()
            Text("Active")
              .foregroundColor(.secondary)
          }
          
          #if !os(macOS)
          Button(action: { UIApplication.openSubscriptionManagement() }, label: {
            Text("Manage in App Store")
          })
          #endif
        }
      } else {
        SupporterPromoView()
      }
    }.navigationTitle("Subscription")
  }
}

struct SubscriptionView_Previews: PreviewProvider {
  static var previews: some View {
    SubscriptionView()
  }
}
