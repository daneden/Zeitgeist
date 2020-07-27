//
//  EmbeddedWebView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 26/07/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct EmbeddedWebView: View {
  var pageURL: String
    var body: some View {
      WebView(request: URLRequest(url: URL(string: pageURL)!))
        .toolbar {
          Link(destination: URL(string: pageURL)!) {
            Label("Open in Safari", systemImage: "safari").labelStyle(IconOnlyLabelStyle())
          }
        }
        .navigationBarTitleDisplayMode(.inline)
        .edgesIgnoringSafeArea(.bottom)
    }
}

struct EmbeddedWebView_Previews: PreviewProvider {
    static var previews: some View {
      EmbeddedWebView(pageURL: "https://daneden.me")
    }
}
