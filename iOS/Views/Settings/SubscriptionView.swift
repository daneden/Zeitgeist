//
//  SubscriptionView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SubscriptionView: View {
  @ObservedObject var iapHelper = IAPHelper.shared
  
  private var activeSubscription: Bool {
    iapHelper.activeSubscriber
  }
  
  var body: some View {
    Form {
      if activeSubscription {
        Section(header: Label("Supporter Subscription", systemImage: "heart"), footer: TermsAndPrivacyView()) {
          HStack {
            Text("Subscription Status")
            Spacer()
            Text("Active")
              .foregroundColor(.secondary)
          }
          
          Text("Thank you for being a supporter of Zeitgeist. You can manage your subscription in the App Store.")
            .font(.footnote)
          
          Button(action: { UIApplication.openSubscriptionManagement() }, label: {
            Text("Manage in App Store")
          })
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
