//
//  DeploymentDetailLabel.swift
//  Verdant
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

struct LabelView<S: View, Content: View>: View {
  var label: () -> S
  var content: Content
  
  init(_ label: @escaping () -> S, @ViewBuilder content: () -> Content) {
    self.label = label
    self.content = content()
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      label()
        .font(.footnote)
        .foregroundColor(.secondary)
      
      content
    }.padding(.vertical, 4)
  }
}

extension LabelView where S == Text {
  init(_ label: String, @ViewBuilder content: () -> Content) {
    self.label = { Text(label) }
    self.content = content()
  }
}

struct DeploymentDetailLabel_Previews: PreviewProvider {
  static var previews: some View {
    LabelView("Label") {
      Text("Value")
    }
  }
}
