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
        DeploymentDetailLabel("Refresh deployments every:") {
          Text("\(Int(refreshFrequency)) seconds").font(.body.bold())
        }
        
        Slider(
          value: $refreshFrequency,
          in: 2...30,
          step: 1,
          minimumValueLabel: Text("2"),
          maximumValueLabel: Text("30")
        ) {
          Text("Refresh Frequency")
        }
        
        Button(action: { refreshFrequency = 5.0 }) {
          Text("Reset To Default")
        }.disabled(refreshFrequency == 5.0)
      }
    }
  }
}

struct RefreshFrequencyView_Previews: PreviewProvider {
    static var previews: some View {
        RefreshFrequencyView()
    }
}
