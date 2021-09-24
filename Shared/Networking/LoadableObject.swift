//
//  LoadableObject.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import Combine

enum LoadingState<Value> {
  case idle
  case loading
  case failed(Error)
  case loaded(Value)
  case refreshing(Value)
}

extension LoadingState: Equatable where Value: Equatable {
  static func == (lhs: LoadingState<Value>, rhs: LoadingState<Value>) -> Bool {
    switch lhs {
    case .idle:
      return rhs == .idle
    case .loading:
      return rhs == .loading
    case .loaded(let leftValue):
      if case .loaded(let rightValue) = rhs,
         leftValue == rightValue {
        return true
      } else {
        return false
      }
    case .refreshing(let leftValue):
      if case .refreshing(let rightValue) = rhs,
         leftValue == rightValue {
        return true
      } else {
        return false
      }
    case .failed:
      return false
    }
  }
}

protocol LoadableObject: ObservableObject {
  associatedtype Output
  var state: LoadingState<Output> { get }
  func load()
  func loadAsync() async
}
