//
//  DeploymentDetailLabel.swift
//  Verdant
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

struct LabelView<Content: View>: View {
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
    LabelView("Label") {
      Text("Value")
    }
  }
}
