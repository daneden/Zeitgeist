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
  var state: VercelDeployment.State
  var style: StateIndicatorStyle = .normal
  
  var label: String {
    state.description
  }
  
  var color: Color {
    switch state {
    case .error:
      return .red
    case .building:
      return .purple
    case .ready:
      return .green
    case .cancelled:
      return .primary
    default:
      return .gray
    }
  }
  
  var iconName: String {
    switch state {
    case .error:
      return "exclamationmark.triangle"
    case .queued, .building:
      return "timer"
    case .ready:
      return "checkmark.circle"
    case .cancelled:
      return "nosign"
    case .offline:
      return "wifi.slash"
    default:
      return "arrowtriangle.up.circle"
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
    .symbolVariant(style == .normal ? .fill : .none)
  }
}

struct DeploymentStateIndicator_Previews: PreviewProvider {
  static var previews: some View {
    Group {
      ForEach(VercelDeployment.State.allCases, id: \.self) { state in
        DeploymentStateIndicator(state: state)
      }
      
      ForEach(VercelDeployment.State.allCases, id: \.self) { state in
        DeploymentStateIndicator(state: state, style: .compact)
      }
    }.previewLayout(.sizeThatFits)
  }
}
