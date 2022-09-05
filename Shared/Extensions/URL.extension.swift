//
//  URL.extension.swift
//  ZeitgeistWidgetsExtension
//
//  Created by Daniel Eden on 03/06/2021.
//

import Foundation

extension URL {
	static var AppStoreURL = URL(string: "https://apps.apple.com/us/app/zeitgeist/id1526052028")!
	static var ReviewURL = URL(string: AppStoreURL.absoluteString.appending("?action=write-review"))!
}
