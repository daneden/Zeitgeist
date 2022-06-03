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
          Text("Show your support for Zeitgeist and its development with a subscription.")
        },
        icon: {
          Image(systemName: "heart.fill")
            .foregroundColor(.pink)
        }
      )
      .font(.footnote.weight(.medium))
      .padding(.vertical, 4)
      
      SubscribeButton()
    }
  }
}

struct SupporterPromoView_Previews: PreviewProvider {
  static var previews: some View {
    SupporterPromoView()
  }
}
