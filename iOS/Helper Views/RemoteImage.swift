//
//  RemoteImage.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

#if os(macOS)
typealias NativeImage = NSImage
#else
typealias NativeImage = UIImage
#endif

import SwiftUI

struct RemoteImage: View {
  private enum LoadState {
    case loading, success, failure
  }
  
  private class Loader: ObservableObject {
    var data = Data()
    var state = LoadState.loading
    
    init(url: String) {
      guard let parsedURL = URL(string: url) else {
        fatalError("Invalid URL: \(url)")
      }
      
      URLSession.shared.dataTask(with: parsedURL) { data, _, _ in
        if let data = data, !data.isEmpty {
          self.data = data
          self.state = .success
        } else {
          self.state = .failure
        }
        
        DispatchQueue.main.async {
          self.objectWillChange.send()
        }
      }.resume()
    }
  }
  
  @StateObject private var loader: Loader
  var loading: Image
  var failure: Image
  
  var body: some View {
    selectImage()
      .resizable()
  }
  
  init(url: String, loading: Image = Image(systemName: "circle"), failure: Image = Image(systemName: "multiply.circle")) {
    _loader = StateObject(wrappedValue: Loader(url: url))
    self.loading = loading
    self.failure = failure
  }
  
  private func selectImage() -> Image {
    switch loader.state {
    case .loading:
      return loading
    case .failure:
      return failure
    default:
      if let image = NativeImage(data: loader.data) {
        #if os(macOS)
        return Image(nsImage: image)
        #else
        return Image(uiImage: image)
        #endif
      } else {
        return failure
      }
    }
  }
}
