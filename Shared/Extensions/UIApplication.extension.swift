//
//  UIApplication.extension.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import UIKit

extension UIApplication {
  class func openAppSettings() {
    guard let url = URL(string: self.openSettingsURLString) else { return }
    self.shared.open(url, options: [:], completionHandler: nil)
  }
  
  class func openSubscriptionManagement() {
    guard let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") else { return }
    self.shared.open(url, options: [:], completionHandler: nil)
  }
}
