//
//  VisualEffectView.swift
//  macOS
//
//  Created by Daniel Eden on 02/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

#if os(iOS)
import UIKit

struct VisualEffectView: UIViewRepresentable {
  var effect: UIVisualEffect?
  func makeUIView(context: UIViewRepresentableContext<Self>) -> UIVisualEffectView { UIVisualEffectView() }
  func updateUIView(_ uiView: UIVisualEffectView, context: UIViewRepresentableContext<Self>) { uiView.effect = effect }
}

#else
import AppKit

struct VisualEffectView: NSViewRepresentable {
  var effect: NSVisualEffectView.Material
  func makeNSView(context: NSViewRepresentableContext<Self>) -> NSVisualEffectView { NSVisualEffectView() }
  func updateNSView(_ nsView: NSVisualEffectView, context: Context) { nsView.material = effect }
}

#endif
