//
//  DeploymentStateIndicator.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

enum StateIndicatorStyle {
  case normal, compact
}

struct DeploymentStateIndicator: View {
  var state: DeploymentState
  var style: StateIndicatorStyle = .normal
  
  var label: String {
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
    case .offline:
      return "Offline"
    default:
      return "Ready" 
    }
  }
  
  var color: Color {
    switch state {
    case .error:
      return .systemRed
    case .building:
      return .systemPurple
    case .ready:
      return .systemGreen
    case .cancelled:
      return .primary
    default:
      return .systemGray
    }
  }
  
  var iconName: String {
    switch state {
    case .error:
      return style == .normal ? "exclamationmark.triangle.fill" : "exclamationmark.triangle"
    case .queued, .building:
      return "timer"
    case .ready:
      return style == .normal ? "checkmark.circle.fill" : "checkmark.circle"
    case .cancelled:
      return "nosign"
    case .offline:
      return "wifi.slash"
    default:
      return "arrowtriangle.up.circle.fill"
    }
  }
  
  var body: some View {
    return Group {
      if style == .normal {
        Label(label, systemImage: iconName)
      } else {
        Label(label, systemImage: iconName)
          .labelStyle(IconOnlyLabelStyle())
      }
    }
    .foregroundStyle(color)
    .symbolRenderingMode(.hierarchical)
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
