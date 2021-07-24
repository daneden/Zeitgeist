//
//  ErrorView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 24/07/2021.
//

import SwiftUI

struct ErrorView: View {
  @ScaledMetric var spacing: CGFloat = 8
  var error: Error
  var retryHandler: (() -> Void)?
  
  var body: some View {
    VStack(alignment: .leading, spacing: spacing) {
      Label(error.localizedDescription, systemImage: "exclamationmark.triangle.fill")
        .foregroundColor(.secondary)
      if let retryHandler = retryHandler {
        Button(action: retryHandler) {
          Label("Try Again", systemImage: "arrow.counterclockwise")
        }
      }
    }
  }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
      ErrorView(error: LoaderError.decodingError)
    }
}
