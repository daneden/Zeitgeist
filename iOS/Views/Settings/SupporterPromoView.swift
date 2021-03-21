//
//  SupporterPromoView.swift
//  iOS
//
//  Created by Daniel Eden on 19/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import SwiftUI
import StoreKit

struct SupporterPromoView: View {
  @State var purchased = false
  
  var body: some View {
    Group {
      VStack(spacing: 4) {
        Image(systemName: "lock.fill")
          .foregroundColor(.systemYellow)
          .font(.title)
        Text("Subscribe to unlock notifications").lineLimit(4)
          .font(Font.headline.bold())
          .padding(.bottom, 4)
          .multilineTextAlignment(.center)
        
        Text("Support the development of Zeitgeist with a subscription to enable push notifications for new and failed builds.")
          .multilineTextAlignment(.center)
      }.padding(.vertical, 8)
      
      SubscribeButton()
    }
  }
}

struct SupporterPromoView_Previews: PreviewProvider {
  static var previews: some View {
    SupporterPromoView()
  }
}
