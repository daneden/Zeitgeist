//
//  LoadableObjectView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 24/07/2021.
//

import SwiftUI

struct LoadableObjectView<T, Content: View>: View {
  var value: LoadingState<T>
  var placeholderData: T?
  var content: (T) -> Content
  
  @State private var isAnimating = false
  
  init(value: LoadingState<T>, placeholderData: T? = nil, @ViewBuilder content: @escaping (T) -> Content) {
    self.value = value
    self.placeholderData = placeholderData
    self.content = content
  }
  
  var body: some View {
    Group {
      switch value {
      case .idle:
        Color.clear
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
        ErrorView(error: error)
      case .loaded(let output):
        content(output)
      case .refreshing(let output):
        content(output)
      }
    }
  }
}
