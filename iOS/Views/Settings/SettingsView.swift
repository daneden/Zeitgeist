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
        NavigationLink(destination: RefreshFrequencyView()) {
          Label("Refresh Frequency", systemImage: "clock.arrow.2.circlepath")
        }
        
        NavigationLink(destination: NotificationsView()) {
          Label("Notifications", systemImage: "app.badge")
        }
        
        NavigationLink(destination: SubscriptionView()) {
          Label("Supporter Subscription", systemImage: "heart.fill")
            .accentColor(.systemPink)
        }
      }
      
      Group {
        NavigationLink(destination: SubmitFeedbackView()) {
          Label("Submit Feedback", systemImage: "ladybug")
        }
        
        Link(destination: .ReviewURL) {
          Label("Review on App Store", systemImage: "app.gift")
        }
      }
      
      Group {
        Link(destination: URL(string: "https://zeitgeist.daneden.me/privacy")!) {
          Text("Privacy Policy")
        }
        
        Link(destination: URL(string: "https://zeitgeist.daneden.me/terms")!) {
          Text("Terms of Use")
        }
      }
    }
    .onAppear {
      IAPHelper.shared.refresh()
    }
    .navigationTitle("Settings")
  }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
