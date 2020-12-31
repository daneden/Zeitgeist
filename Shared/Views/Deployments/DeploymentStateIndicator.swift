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
  
  var body: some View {
    return Group {
      if verbose {
        Label(labelForState(state), systemImage: iconNameForState(state))
      } else {
        Label(labelForState(state), systemImage: iconNameForState(state))
          .labelStyle(IconOnlyLabelStyle())
      }
    }
    .foregroundColor(colorForState(state))
  }
  
  func iconNameForState(_ state: DeploymentState) -> String {
    switch state {
    case .error:
      return verbose ? "exclamationmark.triangle.fill" : "exclamationmark.triangle"
    case .queued, .building:
      return "timer"
    case .ready:
      return verbose ? "checkmark.circle.fill" : "checkmark.circle"
    case .cancelled:
      return "nosign"
    default:
      return "arrowtriangle.up.circle.fill"
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
