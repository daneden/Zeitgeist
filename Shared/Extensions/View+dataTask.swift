//
//  View+dataTask.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 16/07/2022.
//

import SwiftUI

struct DataTaskModifier: ViewModifier {
  let action: () async -> Void
  
  func body(content: Content) -> some View {
    content
      .task { await action() }
      .refreshable { await action() }
      .onReceive(NotificationCenter.default.publisher(for: .ZPSNotification)) { output in
        Task { await action() }
      }
  }
}

extension View {
  func dataTask(perform action: @escaping () async -> Void) -> some View {
    self.modifier(DataTaskModifier(action: action))
  }
}