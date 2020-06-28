//
//  FooterView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct FooterView: View {
  @EnvironmentObject var settings: UserDefaultsManager
  @EnvironmentObject var fetcher: VercelFetcher
  @State private var selectedTeam = 0
  
  var body: some View {
    return VStack(alignment: .leading, spacing: 0) {
      Divider()
      VStack(alignment: .leading) {
        HStack {
          Spacer()
          Button(action: { self.settings.token = nil }) {
            Text("logoutButton")
          }
          Spacer()
        }
      }
      .padding()
    }
  }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
    }
}
