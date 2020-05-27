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
  
  var body: some View {
    return VStack(alignment: .leading, spacing: 0) {
      Divider()
      VStack(alignment: .leading) {
        HStack {
          Button(action: self.resetSession) {
            Text("logoutButton")
          }
          Spacer()
        }
      }
      .font(.caption)
      .padding(8)
    }
  }
  
  func resetSession() {
    self.settings.token = nil
    self.settings.objectWillChange.send()
  }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
    }
}
