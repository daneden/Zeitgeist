//
//  URLWatcher.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 06/01/2022.
//

import Foundation

protocol Watcher: AsyncSequence, AsyncIteratorProtocol where Element == Data {
  var comparisonData: Element? { get set }
  var isActive: Bool { get set }
  var delay: Int { get }
  
  func fetchData() async throws -> Element
  
  func makeAsyncIterator() -> Self
  mutating func next() async throws -> Element?
}

struct URLRequestWatcher: Watcher {
  typealias Element = Data
  
  let urlRequest: URLRequest
  var delay: Int = 10
  internal var comparisonData: Data?
  internal var isActive = true
  
  func fetchData() async throws -> Data {
    let (data, _) = try await URLSession.shared.data(for: urlRequest)
    return data
  }
  
  func makeAsyncIterator() -> URLRequestWatcher {
    self
  }
  
  mutating func next() async throws -> Data? {
    // Once we're inactive always return nil immediately
    guard isActive else { return nil }
    
    if comparisonData == nil {
      // If this is our first iteration, return the initial value
      comparisonData = try await fetchData()
    } else {
      // Otherwise, sleep for a while and see if our data changed
      while true {
        try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
        
        let latestData = try await fetchData()
        
        if latestData != comparisonData {
          // New data is different from previous data,
          // so update previous data and send it back
          comparisonData = latestData
          break
        }
      }
    }
    
    if comparisonData == nil {
      isActive = false
      return nil
    } else {
      return comparisonData
    }
  }
}
