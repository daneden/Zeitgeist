//
//  Network.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Combine

protocol Network {
  var decoder: JSONDecoder { get set }
  var environment: NetworkEnvironment { get set }
}

extension Network {
  func fetch<T: Decodable>(route: NetworkRoute) -> AnyPublisher<T, Error> {
    let request = route.create(for: environment)

    return URLSession.shared
      .dataTaskPublisher(for: request)
      .tryCompactMap { result in
        let value = try self.decoder.decode(T.self, from: result.data)
        return value
    }
    .receive(on: RunLoop.main)
    .eraseToAnyPublisher()
  }
}
