//
//  DeploymentsListView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

struct DeploymentsListView: View {
  @EnvironmentObject var settings: UserDefaultsManager
  @EnvironmentObject var vercelFetcher: VercelFetcher

  var body: some View {
    return VStack {
      if vercelFetcher.fetchState == .loading {
        Spacer()
        ProgressView("Loading...")
        Spacer()
      } else {
        if vercelFetcher.deployments.isEmpty {
            VStack(spacing: 0) {
              Spacer()
              Text("emptyState")
                .foregroundColor(.secondary)
              Spacer()
            }
          } else {
            List {
              ForEach(vercelFetcher.deployments, id: \.self) { deployment in
                DeploymentsListRowView(deployment: deployment)
              }
            }.listStyle(PlainListStyle()).listRowInsets(.none)
          }
      }
    }
      .id(!vercelFetcher.deployments.isEmpty ? vercelFetcher.deployments[0].hashValue : 1)
      .onAppear {
        vercelFetcher.loadDeployments()
        vercelFetcher.loadTeams()
      }
      .frame(minWidth: 0, idealWidth: 0, maxWidth: .infinity)
  }
}

struct NetworkError: View {
  var body: some View {
    VStack {
      Image("networkOfflineIcon")
        .foregroundColor(.secondary)
      Text("offlineHeading")
        .font(.subheadline)
        .fontWeight(.bold)
      Text("offlineDescription")
        .multilineTextAlignment(.center)
        .lineLimit(10)
        .frame(minWidth: 0, minHeight: 0, maxHeight: 40)
        .layoutPriority(1)
        .foregroundColor(.secondary)
    }.padding()
  }
}

//struct DeploymentsListView_Previews: PreviewProvider {
//  static var previews: some View {
//    DeploymentsListView()
//  }
//}