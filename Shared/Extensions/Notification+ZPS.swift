//
//  Notification+ZPS.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/07/2022.
//

import Foundation

extension Notification.Name {
	static var ZPSNotification = Notification.Name("ZPSNotification")
	
	static var VercelAccountAddedNotification = Notification.Name("VercelAccountAddedNotification")
	static var VercelAccountWillBeRemovedNotification = Notification.Name("VercelAccountWillBeRemovedNotification")
}
