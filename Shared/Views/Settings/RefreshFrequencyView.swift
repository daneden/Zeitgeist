//
//  RefreshFrequencyView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct RefreshFrequencyView: View {
  @AppStorage("refreshFrequency") var refreshFrequency: Double = 5.0
  
  var body: some View {
    Form {
      Section(footer: Text("Lower values may negatively impact app performance")) {
        Stepper(
          value: $refreshFrequency,
          in: 2...30,
          step: 1
        ) {
          DeploymentDetailLabel("Refresh deployments every:") {
            Text("\(Int(refreshFrequency)) seconds")
          }
        }
        
        Button(action: { refreshFrequency = 5.0 }) {
          Text("Reset To Default")
        }.disabled(refreshFrequency == 5.0)
      }
    }.navigationTitle("Refresh Frequency")
  }
}

struct RefreshFrequencyView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshFrequencyView()
    }
}
