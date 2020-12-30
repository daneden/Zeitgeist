//
//  Color.extension.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 30/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
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
   System Colors
   */
  static var systemBlue = Color(TColor.systemBlue)
  static var systemGreen = Color(TColor.systemGreen)
  static var systemIndigo = Color(TColor.systemIndigo)
  static var systemOrange = Color(TColor.systemOrange)
  static var systemPink = Color(TColor.systemPink)
  static var systemPurple = Color(TColor.systemPurple)
  static var systemRed = Color(TColor.systemRed)
  static var systemTeal = Color(TColor.systemTeal)
  static var systemYellow = Color(TColor.systemYellow)
  
  /**
   System Grays
   */
  static var systemGray = Color(TColor.systemGray)
  #if !os(macOS)
  static var systemGray2 = Color(TColor.systemGray2)
  static var systemGray3 = Color(TColor.systemGray3)
  static var systemGray4 = Color(TColor.systemGray4)
  static var systemGray5 = Color(TColor.systemGray5)
  static var systemGray6 = Color(TColor.systemGray6)
  #endif
  
  /**
   Separator Colors
   */
  #if os(macOS)
  static var separator = Color(TColor.separatorColor)
  #else
  static var separator = Color(TColor.separator)
  static var opaqueSeparator = Color(TColor.opaqueSeparator)
  #endif
  
  /**
   Text Colors
   */
  #if os(macOS)
  static var label = Color(TColor.labelColor)
  static var secondaryLabel = Color(TColor.secondaryLabelColor)
  static var tertiaryLabel = Color(TColor.tertiaryLabelColor)
  static var quarternaryLabel = Color(TColor.quaternaryLabelColor)
  static var placeholderText = Color(TColor.placeholderTextColor)
  static var link = Color(TColor.linkColor)
  #else
  static var label = Color(TColor.label)
  static var secondaryLabel = Color(TColor.secondaryLabel)
  static var tertiaryLabel = Color(TColor.tertiaryLabel)
  static var quarternaryLabel = Color(TColor.quaternaryLabel)
  static var placeholderText = Color(TColor.placeholderText)
  static var link = Color(TColor.link)
  #endif
  
  /**
   System Fills/Background
   */
  #if !os(macOS)
  static var systemFill = Color(TColor.systemFill)
  static var secondarySystemFill = Color(TColor.secondarySystemFill)
  static var tertiarySystemFill = Color(TColor.tertiarySystemFill)
  static var quarternarySystemFill = Color(TColor.quaternarySystemFill)
  
  static var systemBackground = Color(TColor.systemBackground)
  static var secondarySystemBackground = Color(TColor.secondarySystemBackground)
  static var tertiarySystemBackground = Color(TColor.tertiarySystemBackground)
  
  static var systemGroupedBackground = Color(TColor.systemGroupedBackground)
  static var secondarySystemGroupedBackground = Color(TColor.secondarySystemGroupedBackground)
  static var tertiarySystemGroupedBackground = Color(TColor.tertiarySystemGroupedBackground)
  #endif
}
