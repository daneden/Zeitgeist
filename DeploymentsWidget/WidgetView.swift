//
//  DeploymentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct WidgetView: View {
  var model: WidgetContent
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    VStack(alignment: .leading) {
      DeploymentStateIndicator(state: model.status, verbose: true, isWidget: true)
      
      Text(model.title)
        .fontWeight(.bold)
        .lineLimit(3)
        .foregroundColor(.primary)
      Text(model.date, style: .relative)
        .font(.caption)
        .foregroundColor(.secondary)
      
      Spacer()
      
      Text("\(model.project)")
        .font(.caption).font(.caption)
      
    }
    .padding()
    .background(Color(TColor.systemBackground))
  }
}
