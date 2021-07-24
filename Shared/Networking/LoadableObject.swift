//
//  LoadableObject.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation
import Combine

protocol LoadableObject: ObservableObject {
  associatedtype Output
  var state: LoadingState<Output> { get }
  func load()
}
