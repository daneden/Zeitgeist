//
//  DeploymentView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct DeploymentView: View {
  let model: WidgetContent
  
  var body: some View {
    VStack(alignment: .leading) {
      HStack {
        Text("Latest deployment:")
          .font(.caption)
          .foregroundColor(.secondary)
        Spacer()
      }

      Spacer()
      
      DeploymentStateIndicator(state: model.status, verbose: true)
      Text(model.title)
        .font(Font.body.bold())
        .lineLimit(3)
        .foregroundColor(.primary)
          
      Text("\(model.project)")
        .font(.caption).font(.caption)
      
      
      Text(model.date, style: .relative)
        .font(.caption)
        .foregroundColor(.secondary)
      
      Spacer()
    }
    .cornerRadius(6)
    .padding()
  }
}
