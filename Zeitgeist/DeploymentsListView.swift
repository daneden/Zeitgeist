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
  @State var isPreferencesShown = false
  
  let updateStatusOverview = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
  
  var body: some View {
    VStack {
      viewModel.resource.hasError() { error in
        if (error is URLError) {
          NetworkError()
            .padding(.bottom, 40)
        } else {
          VStack {
            Image("errorSplashIcon")
            Text("Something went wrong")
              .font(.subheadline)
              .fontWeight(.bold)
            Text("Are you sure you entered your Zeit token correctly?")
              .multilineTextAlignment(.center)
              .lineLimit(10)
              .frame(minWidth: 0, minHeight: 0, maxHeight: 40)
              .layoutPriority(1)
            Button(action: self.resetSession) {
              Text("Go Back")
            }
          }
          .padding(.bottom, 40)
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
          VStack(alignment: .leading, spacing: 0) {
            List {
              ForEach(result.deployments, id: \.id) { deployment in
                DeploymentsListRowView(deployment: deployment)
              }
            }
            Divider()
            VStack(alignment: .leading) {
              HStack {
                Button(action: self.resetSession) {
                  Text("Log Out")
                }
                Spacer()
//                Button(action: {self.isPreferencesShown.toggle()}) {
//                  Text("Settings")
//                }
              }
            }
            .font(.caption)
            .padding(8)
          }.onReceive(self.updateStatusOverview, perform: { _ in
            let delegate: AppDelegate? = NSApplication.shared.delegate as? AppDelegate
            delegate?.setIconBasedOnState(state: result.deployments[0].state)
          })
        }
      }
    }
      .onAppear(perform: viewModel.onAppear)
      .sheet(isPresented: $isPreferencesShown) {
        PreferencesView()
      }
  }
  
  func resetSession() -> Void {
    self.settings.token = nil
    self.settings.objectWillChange.send()
  }
}

struct NetworkError: View {
  var body: some View {
    VStack {
      Image("networkOfflineIcon")
      Text("Network Offline")
        .font(.subheadline)
        .fontWeight(.bold)
      Text("Zeitgeist will automatically try again when a network connection is available.")
        .multilineTextAlignment(.center)
        .lineLimit(10)
        .frame(minWidth: 0, minHeight: 0, maxHeight: 40)
        .layoutPriority(1)
        .foregroundColor(.secondary)
    }
  }
}


struct DeploymentsListView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentsListView()
  }
}
