//
//  DeploymentStateIndicator.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct DeploymentStateIndicator: View {
  var state: DeploymentState
  var verbose: Bool = false
  var isWidget: Bool = false
  
  #if os(macOS)
  let badgeBackground = VisualEffectView(effect: .windowBackground)
  #else
  let badgeBackground = VisualEffectView(effect: UIBlurEffect(style: .systemThickMaterial))
  #endif
  
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
    .font(Font.footnote.bold())
    .foregroundColor(colorForState(state))
    .background(verbose ? colorForState(state).opacity(0.1) : nil)
    .background(badgeBackground.opacity(verbose && !isWidget ? 1.0 : 0))
    .cornerRadius(verbose ? 8 : 0)
    .padding(.bottom, isWidget ? -4 : 4)
  }
  
  func iconForState(_ state: DeploymentState) -> Image {
    switch state {
    case .error:
      return Image(systemName: verbose ? "exclamationmark.circle.fill" : "exclamationmark.triangle.fill")
    case .queued, .building:
      return Image(systemName: "timer")
    case .ready:
      return Image(systemName: verbose ? "checkmark.circle.fill" : "checkmark.circle")
    case .cancelled:
      return Image(systemName: "nosign")
    default:
      return Image(systemName: "arrowtriangle.up.circle.fill")
    }
  }
  
  func colorForState(_ state: DeploymentState) -> Color {
    switch state {
    case .error:
      return .systemRed
    case .building:
      return .systemPurple
    case .ready:
      return .systemGreen
    default:
      return .systemGray
    
    }
  }
  
  func labelForState(_ state: DeploymentState) -> String {
    switch state {
    case .error:
      return "Error building"
    case .building:
      return "Building"
    case .ready:
      return "Deployed"
    case .queued:
      return "Queued"
    case .cancelled:
      return "Cancelled"
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
