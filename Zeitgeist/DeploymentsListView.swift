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
            Deployment(deployment: deployment)
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

struct ProgressIndicator: NSViewRepresentable {
  func makeNSView(context: NSViewRepresentableContext<ProgressIndicator>) -> NSProgressIndicator {
    let result = NSProgressIndicator()
    result.isIndeterminate = true
    result.startAnimation(nil)
    result.controlSize = .small
    result.style = .spinning
    return result
  }
  
  func updateNSView(_ nsView: NSProgressIndicator, context: NSViewRepresentableContext<ProgressIndicator>) {
    
  }
}

struct DeploymentStateIndicator: View {
  var state: ZeitDeploymentState
  let size = CGFloat(14.0)
  var body: some View {
    Group {
      if(state == .queued) {
        Image("clock")
          .resizable()
          .frame(width: size, height: size, alignment: .center)
      } else if (state == .error) {
        Image("error")
          .resizable()
          .frame(width: size, height: size, alignment: .center)
      } else if (state == .building) {
        ProgressIndicator()
      } else {
        Image("check")
          .resizable()
          .frame(width: size, height: size, alignment: .center)
      }
    }
  }
}

struct Deployment: View {
  var deployment: ZeitDeployment
  var body: some View {
    Button(action: self.openDeployment) {
      HStack {
        VStack(alignment: .leading) {
          Text("\(deployment.name)")
            .fontWeight(.bold)
          Text("\(deployment.url)")
            .foregroundColor(.secondary)
          Text("\(deployment.relativeTimestamp)")
            .foregroundColor(.secondary)
            .font(.caption)
            .opacity(0.75)
        }
        Spacer()
        DeploymentStateIndicator(state: deployment.state)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .padding(.vertical, 4)
    .contextMenu{
      Button(action: self.openDeployment) {
        Text("Open URL")
      }
      
      Button(action: self.copyURL) {
        Text("Copy URL")
      }
      
      Button(action: self.openInspector) {
        Text("Open Deployment Inspector")
      }
    }
  }
  
  func openDeployment() -> Void {
    if let url = URL(string: "\(deployment.absoluteURL)") {
      NSWorkspace.shared.open(url)
    }
  }
  
  func openInspector() -> Void {
    if let url = URL(string: "\(deployment.absoluteURL)/_logs") {
      NSWorkspace.shared.open(url)
    }
  }
  
  func copyURL() -> Void {
    let pb = NSPasteboard.general
    pb.clearContents()
    pb.setString(deployment.absoluteURL, forType: .string)
  }
}


struct DeploymentsListView_Previews: PreviewProvider {
  static var previews: some View {
    DeploymentsListView()
  }
}
