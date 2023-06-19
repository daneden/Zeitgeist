//
//  Date+RawRepresentable.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 19/06/2023.
//

import Foundation

/// Allows dates to be stored in AppStorage
extension Date: RawRepresentable {
	public var rawValue: String {
		self.timeIntervalSinceReferenceDate.description
	}
	
	public init?(rawValue: String) {
		self = Date(timeIntervalSinceReferenceDate: Double(rawValue) ?? 0.0)
	}
}
