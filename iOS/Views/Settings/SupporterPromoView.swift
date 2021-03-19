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
    Section {
      VStack(alignment: .leading) {
        Text("Become a Zeitgeist supporter")
          .font(.headline)
        
        Text("Support the development of Zeitgeist and enable push notifications for new and failed builds with a monthly subscription.")
      }.padding(.vertical)
      
      SubscribeButton(purchased: $purchased)
    }
  }
}

struct SupporterPromoView_Previews: PreviewProvider {
  static var previews: some View {
    SupporterPromoView()
  }
}
