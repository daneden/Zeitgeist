//
//  SupporterPromoView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SupporterPromoView: View {
  var body: some View {
    Section(header: Text("Become a Supporter"), footer: TermsAndPrivacyView()) {
      Label(
        title: {
          HStack {
            VStack(alignment: .leading, spacing: 4) {
              Text("Subscribe to unlock notifications")
                .fontWeight(.bold)
              
              Text("Support the development of Zeitgeist with a subscription to enable push notifications for new and failed builds.")
            }
            Spacer()
          }
        },
        icon: {
          Image(systemName: "heart.fill")
            .foregroundColor(.pink)
        }
      )
      .font(.footnote)
      .padding(8)
      .background(Color.pink.opacity(0.05))
      .cornerRadius(12)
      .padding(.leading, -8)
      
      SubscribeButton()
    }
  }
}

struct SupporterPromoView_Previews: PreviewProvider {
  static var previews: some View {
    SupporterPromoView()
  }
}
