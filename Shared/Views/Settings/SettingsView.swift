//
//  SettingsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SettingsView: View {
  var body: some View {
    Form {
      Section(header: Text("Settings")) {
        NavigationLink(destination: NotificationsView()) {
          Label("Notifications", systemImage: "app.badge")
        }
        
        NavigationLink(destination: SubscriptionView()) {
          Label("Supporter Subscription", systemImage: "heart.fill")
            .accentColor(.pink)
        }
      }
      
      Section {
        Link(destination: URL(string: "https://github.com/daneden/zeitgeist/issues")!) {
          Label("Submit Feedback", systemImage: "ladybug")
        }
        
        Link(destination: .ReviewURL) {
          Label("Review on App Store", systemImage: "star.fill")
        }
      }
      
      Section {
        Link(destination: URL(string: "https://zeitgeist.daneden.me/privacy")!) {
          Text("Privacy Policy")
        }
        
        Link(destination: URL(string: "https://zeitgeist.daneden.me/terms")!) {
          Text("Terms of Use")
        }
      }
    }
    .navigationTitle("Settings")
  }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
