//
//  RecentDeploymentsWidgetView.swift
//  iOS
//
//  Created by Daniel Eden on 03/10/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct RecentDeploymentsWidgetView: View {
  var entries: [WidgetContent]
  @Environment(\.colorScheme) var colorScheme
  
  var body: some View {
    VStack(alignment: .leading) {
      Text("Recent deployments")
        .font(.footnote).fontWeight(.semibold)
      
      Divider().padding(.bottom, 4)
      
      ForEach(entries.prefix(7), id: \.self) { model in
        HStack(alignment: .top) {
          DeploymentStateIndicator(state: model.status, verbose: false, isWidget: true)
        
          VStack(alignment: .leading) {
            Text(model.title)
              .fontWeight(.bold)
              .lineLimit(3)
              .foregroundColor(.primary)
            
            HStack {
              Text("\(model.project)")
                .foregroundColor(.secondary)
              
              Text(model.date, style: .relative)
                .foregroundColor(.secondary)
            }
          }
          
          Spacer()
        }
        .padding(.bottom, 4)
        .font(.footnote)
      }
      
      Spacer()
    }
    .padding()
    .background(Color(TColor.systemBackground))
  }
}

struct RecentDeploymentsWidgetView_Previews: PreviewProvider {
    static var previews: some View {
      RecentDeploymentsWidgetView(entries: [snapshotEntry, snapshotEntry])
    }
}
