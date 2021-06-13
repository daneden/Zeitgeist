//
//  URLSession.extension.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/06/2021.
//

import Foundation
import Combine

extension URLSession {
  func publisher<T: Decodable>(
    for request: URLRequest,
    responseType: T.Type = T.self,
    decoder: JSONDecoder = .init()
  ) -> AnyPublisher<T, Error> {
    dataTaskPublisher(for: request)
      .map(\.data)
      .decode(type: T.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
  
  func publisher<T: Decodable>(
    for url: URL,
    responseType: T.Type = T.self,
    decoder: JSONDecoder = .init()
  ) -> AnyPublisher<T, Error> {
    dataTaskPublisher(for: url)
      .map(\.data)
      .decode(type: T.self, decoder: decoder)
      .eraseToAnyPublisher()
  }
}
