//
//  PublishedObject.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import Combine
import SwiftUI

class PublishedObject<Wrapped: Publisher>: LoadableObject {
  @Published private(set) var state = LoadingState<Wrapped.Output>.idle
  
  private let publisher: Wrapped
  private var cancellable: AnyCancellable?
  
  init(publisher: Wrapped) {
    self.publisher = publisher
  }
  
  func load() {
    state = .loading
    
    cancellable = publisher
      .map(LoadingState.loaded)
      .catch { error in
        Just(LoadingState.failed(error))
      }
      .sink { [weak self] state in
        self?.state = state
      }
  }
}

extension AsyncContentView {
  init<P: Publisher>(
    source: P,
    @ViewBuilder content: @escaping (P.Output) -> Content
  ) where Source == PublishedObject<P> {
    self.init(
      source: PublishedObject(publisher: source),
      content: content
    )
  }
}
