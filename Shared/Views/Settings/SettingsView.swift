//
//  SettingsView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct SettingsView: View {
  var githubIssuesURL: URL {
    let appVersion: String? = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    let body = """
> Please give a detailed description of the issue you’re experiencing or the feedback you’d like to provide.
> Feel free to attach any relevant screenshots or logs, and please keep the app version and device info in the issue!

App Version: \(appVersion ?? "Unknown")
Device: \(UIDevice.modelName)
OS: \(UIDevice.current.systemName) \(UIDevice.current.systemVersion)
"""
    let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryValueAllowed) ?? ""
    
    return URL(string: "https://github.com/daneden/zeitgeist/issues/new?body=\(encodedBody)")!
  }
  
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
        Link(destination: githubIssuesURL) {
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
