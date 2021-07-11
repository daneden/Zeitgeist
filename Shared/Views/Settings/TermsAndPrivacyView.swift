//
//  TermsAndPrivacyView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 10/06/2021.
//

import SwiftUI

struct TermsAndPrivacyView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Link(destination: URL(string: "https://zeitgeist.daneden.me/privacy")!) {
        Text("Privacy Policy")
      }
      
      Link(destination: URL(string: "https://zeitgeist.daneden.me/terms")!) {
        Text("Terms of Use")
      }
    }
  }
}

struct TermsAndPrivacyView_Previews: PreviewProvider {
    static var previews: some View {
        TermsAndPrivacyView()
    }
}
