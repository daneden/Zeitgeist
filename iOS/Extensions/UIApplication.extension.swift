//
//  UIApplication.extension.swift
//  iOS
//
//  Created by Daniel Eden on 21/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import UIKit

extension UIApplication {
  class func openAppSettings() {
    guard let url = URL(string: self.openSettingsURLString) else { return }
    self.shared.open(url, options: [:], completionHandler: nil)
  }
  
  class func openSubscriptionManagement() {
    guard let url = URL(string: "itms://apps.apple.com/account/subscriptions") else { return }
    self.shared.open(url, options: [:], completionHandler: nil)
  }
}
