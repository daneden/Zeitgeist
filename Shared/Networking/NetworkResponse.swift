//
//  NetworkResponse.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 24/07/2021.
//

import Foundation
import Combine

struct NetworkResponse<Wrapped: Decodable>: Decodable {
  var result: Wrapped
}

protocol NetworkResponseConforming {
  associatedtype Value: Decodable
  var result: Value { get }
}

extension URLSession {
  func publisher<T: Decodable>(
    for request: URLRequest,
    responseType: T.Type = T.self,
    decoder: JSONDecoder = .init()) -> AnyPublisher<T, Error> {
    dataTaskPublisher(for: request)
      .map(\.data)
      .decode(type: NetworkResponse<T>.self, decoder: decoder)
      .map(\.result)
      .eraseToAnyPublisher()
  }
}
