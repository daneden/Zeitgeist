//
//  PlaceholderView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

enum PlaceholderRole {
  case DeploymentList, DeploymentDetail, NoDeployments, NoAccounts
}

struct PlaceholderView: View {
  @ScaledMetric var spacing: CGFloat = 4
  var forRole: PlaceholderRole
  
  var imageName: String {
    switch forRole {
    case .DeploymentDetail:
      return "doc.text.magnifyingglass"
    case .DeploymentList:
      return "person.2.fill"
    case .NoDeployments:
      return "text.badge.xmark"
    case .NoAccounts:
      return "person.3.fill"
    }
  }
  
  var text: String {
    switch forRole {
    case .DeploymentDetail:
      return "No Deployment Selected"
    case .DeploymentList:
      return "No Account Selected"
    case .NoDeployments:
      return "No Deployments To Show"
    case .NoAccounts:
      return "No Accounts Found"
    }
  }
  
  var body: some View {
    VStack(spacing: spacing) {
      Image(systemName: imageName)
        .imageScale(.large)
      Text(text)
    }
    .foregroundColor(.secondary)
    .padding()
  }
}

struct PlaceholderView_Previews: PreviewProvider {
  static var previews: some View {
    PlaceholderView(forRole: .DeploymentDetail)
  }
}
