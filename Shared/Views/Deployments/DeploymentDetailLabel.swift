//
//  DeploymentDetailLabel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 31/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct DeploymentDetailLabel<Content: View>: View {
  var label: String
  var content: Content
  
  init(_ label: String, @ViewBuilder content: () -> Content) {
    self.label = label
    self.content = content()
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      Text(label)
        .font(.footnote)
        .foregroundColor(.secondary)
      
      content
    }.padding(.vertical, 4)
  }
}

struct DeploymentDetailLabel_Previews: PreviewProvider {
    static var previews: some View {
      DeploymentDetailLabel("Label") {
        Text("Value")
      }
    }
}
