//
//  DeploymentsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI
import Cocoa

struct DeploymentsListView: View {
  @EnvironmentObject var viewModel: ZeitDeploymentsViewModel
  @EnvironmentObject var settings: UserDefaultsManager
  var body: some View {
    VStack {
      viewModel.resource.hasError() { error in
        VStack {
          Text("Something went wrong")
            .font(.subheadline)
          Text("Are you sure you entered your Zeit token correctly?")
            .multilineTextAlignment(.center)
            .lineLimit(10)
            .frame(minWidth: 0, minHeight: 0, maxHeight: 40)
            .layoutPriority(1)
          Button(action: self.resetSession) {
            Text("Go Back")
          }
        }
      }
      
      viewModel.resource.isLoading() {
        ProgressIndicator()
      }
      
      viewModel.resource.hasResource() { result in
        if(result.deployments.count <= 0) {
          Spacer()
          Text("No Deployments Found")
            .foregroundColor(.secondary)
          Spacer()
        } else {
          List(result.deployments, id: \.id) { deployment in
            DeploymentsListRowView(deployment: deployment)
          }
        }
      }
    }.onAppear(perform: viewModel.onAppear)
  }
  
  func resetSession() -> Void {
    self.settings.token = nil
    self.settings.objectWillChange.send()
  }
}


struct DeploymentsListView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentsListView()
  }
}
