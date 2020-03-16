//
//  PreferencesView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct PreferencesView: View {
  @Environment(\.presentationMode) var presentationMode
  @ObservedObject var settings = UserDefaultsManager()
  @State private var fetchPeriod: Int = 3

  var body: some View {
    VStack {
      Picker(selection: $fetchPeriod, label: Text("Refresh every:")) {
        Text("3 seconds").tag(3)
        Text("5 seconds").tag(5)
        Text("10 seconds").tag(10)
        Text("30 seconds").tag(30)
      }

      HStack {
        Spacer()
        Button(action: self.dismissView) {
          Text("Save")
        }
        Button(action: self.dismissViewForgettingChanges) {
          Text("Cancel")
        }
      }
    }
      .padding()
      .frame(minWidth: 280, maxWidth: .infinity)
      .onAppear {
        self.fetchPeriod = self.settings.fetchPeriod ?? 3
      }
  }

  func dismissView() {
    self.settings.fetchPeriod = self.$fetchPeriod.wrappedValue
    self.presentationMode.wrappedValue.dismiss()
    self.settings.objectWillChange.send()
  }

  func dismissViewForgettingChanges() {
    self.fetchPeriod = self.settings.fetchPeriod ?? 3
    self.presentationMode.wrappedValue.dismiss()
  }
}

struct PreferencesView_Previews: PreviewProvider {
  static var previews: some View {
    PreferencesView()
  }
}
