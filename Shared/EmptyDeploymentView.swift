//
//  EmptyDeploymentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct EmptyDeploymentView: View {
  var body: some View {
    return VStack {
      Spacer()
      Image(systemName: "triangle.circle.fill")
        .imageScale(.large)
        .font(.largeTitle)
      Text("Select a deployment for details")
      Spacer()
    }.foregroundColor(.secondary)
  }
}

struct EmptyDeploymentView_Previews: PreviewProvider {
    static var previews: some View {
        EmptyDeploymentView()
    }
}
