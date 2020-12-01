//
//  MainViewController.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 29/11/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import AppKit

class MainViewController: NSViewController {
  override func viewDidAppear() {
    super.viewDidAppear()
  }
  
  @IBAction public func openPopover(_ sender: AnyObject) {
    // swiftlint:disable force_cast
    let delegate = NSApplication.shared.delegate as! AppDelegate
    if !delegate.popover.isShown {
      delegate.statusBar?.showPopover(sender)
    }
  }
}
