//
//  Color.extension.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import Foundation
import SwiftUI

#if !os(macOS)
import UIKit
typealias TColor = UIColor
#else
import AppKit
typealias TColor = NSColor
#endif

extension Color {
  /**
   System Fills/Background
   */
  #if !os(macOS)
  static var systemBackground = Color(TColor.systemBackground)
  static var secondarySystemBackground = Color(TColor.secondarySystemBackground)
  #else
  static var systemBackground = Color(TColor.windowBackgroundColor)
  static var secondarySystemBackground = Color(TColor.underPageBackgroundColor)
  #endif
}
