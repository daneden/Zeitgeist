//
//  DeploymentStateIndicator.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

#if !os(macOS)
import UIKit
typealias TColor = UIColor
#else
import AppKit
typealias TColor = NSColor
#endif

struct DeploymentStateIndicator: View {
  var state: VercelDeploymentState
  var verbose: Bool = false
  
  var body: some View {
    HStack(spacing: 4) {
      iconForState(state).imageScale(verbose ? .medium : .large)
      if verbose {
        Text(labelForState(state))
          .padding(.trailing, 4)
      }
    }
    .padding(.vertical, 1)
    .padding(.horizontal, verbose ? 2 : 1)
    .font(Font.caption.bold())
    .foregroundColor(colorForState(state))
    .background(verbose ? colorForState(state).opacity(0.1) : nil)
    .cornerRadius(verbose ? 8 : 0)
    .padding(.bottom, 4)
  }
  
  func iconForState(_ state: VercelDeploymentState) -> Image {
    switch state {
    case .error:
      return Image(systemName: "exclamationmark.triangle.fill")
    case .building:
      return Image(systemName: "timer")
    case .ready:
      return Image(systemName: verbose ? "checkmark.circle.fill" : "checkmark.circle")
    default:
      return Image(systemName: "hourglass")
    }
  }
  
  func colorForState(_ state: VercelDeploymentState) -> Color {
    switch state {
    case .error:
      return Color(TColor.systemOrange)
    case .building:
      return Color(TColor.systemPurple)
    case .ready:
      return Color(TColor.systemGreen)
    default:
      return Color(TColor.systemGray)
    
    }
  }
  
  func labelForState(_ state: VercelDeploymentState) -> String {
    switch state {
    case .error:
      return "Error building"
    case .building:
      return "Building"
    case .ready:
      return "Deployed"
    default:
      return "Ready"
    
    }
  }
}

struct DeploymentStateIndicator_Previews: PreviewProvider {
    static var previews: some View {
      Group {
        DeploymentStateIndicator(state: .building)
        DeploymentStateIndicator(state: .error)
        DeploymentStateIndicator(state: .normal)
        DeploymentStateIndicator(state: .queued)
        DeploymentStateIndicator(state: .offline)
        DeploymentStateIndicator(state: .ready)
      }
    }
}
