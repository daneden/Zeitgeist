//
//  VercelRecord.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/08/2022.
//

import Foundation

protocol Timestamped {
	var timestamp: Date { get }
}

protocol VercelRecord: Identifiable, Timestamped {}
