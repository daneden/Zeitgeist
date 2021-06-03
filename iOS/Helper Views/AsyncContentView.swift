//
//  AsyncContentView.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

struct ErrorView: View {
  var error: Error
  var retryHandler: (() -> Void)?
  
  var body: some View {
    VStack {
      Text(error.localizedDescription)
      if let retryHandler = retryHandler {
        Button(action: retryHandler) {
          Label("Try Again", systemImage: "arrow.counterclockwise")
        }
      }
    }
  }
}

struct AsyncContentView<Source: LoadableObject, Content: View>: View {
  @ObservedObject var source: Source
  var placeholderData: Source.Output?
  var content: (Source.Output) -> Content
  
  @State var isAnimating = false
  
  init(source: Source,
       placeholderData: Source.Output? = nil,
       @ViewBuilder content: @escaping (Source.Output) -> Content) {
    self.source = source
    self.placeholderData = placeholderData
    self.content = content
  }
  
  var body: some View {
    switch source.state {
    case .idle:
      Color.clear.onAppear(perform: source.load)
    case .loading:
      if let placeholderData = placeholderData {
        content(placeholderData)
          .redacted(reason: .placeholder)
          .opacity(isAnimating ? 0.5 : 1)
          .animation(Animation.easeInOut(duration: 1).repeatForever(autoreverses: true))
          .onAppear { self.isAnimating = true }
      } else {
        ProgressView()
      }
    case .failed(let error):
      ErrorView(error: error, retryHandler: source.load)
    case .loaded(let output):
      content(output)
    }
  }
}