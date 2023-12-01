//
//  VercelProjectModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import Foundation
import SwiftUI

struct VercelProject: Decodable, Identifiable {
	typealias ID = String
	let accountId: String
	let createdAt: Int
	let id: ID
	let latestDeployments: [VercelDeployment]?
	let name: String
	let targets: Targets?
	let updatedAt: Int?
	let link: VercelRepositoryLink?
}

extension VercelProject {
	var created: Date {
		Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
	}

	var updated: Date? {
		guard let updatedAt = updatedAt else { return nil }
		return Date(timeIntervalSince1970: TimeInterval(updatedAt / 1000))
	}
}

extension VercelProject {
	struct APIResponse: Decodable {
		let projects: [VercelProject]
		let pagination: Pagination
	}

	struct Targets: Decodable {
		let production: VercelDeployment?
	}
}

struct Pagination: Codable {
	let count: Int
	let prev: Int?
	let next: Int?
}

struct VercelEnv: Codable, Identifiable, Hashable {
	let id: String
	let type: EnvType
	let key: String
	let value: String
	let configurationId: String?
	let createdAt: Int
	let updatedAt: Int
	let gitBranch: String?
	let createdBy: String?
	let updatedBy: String?
	let decrypted: Bool?
	let target: [String]
}

extension VercelEnv {
	var created: Date {
		Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
	}
	
	var updated: Date {
		Date(timeIntervalSince1970: TimeInterval(updatedAt / 1000))
	}
	
	enum EnvType: String, Codable {
		case system, secret, encrypted, plain
	}
	
	struct APIResponse: Codable {
		var envs: [VercelEnv]
		var pagination: Pagination?
	}
	
	var targetsProduction: Bool { target.contains(where: { $0 == "production" }) }
	var targetsPreview: Bool { target.contains(where: { $0 == "preview" }) }
	var targetsDevelopment: Bool { target.contains(where: { $0 == "development" }) }
}

@available (iOS 16.0, *)
extension VercelEnv: Transferable {
	func data() -> Data {
		guard let data = try? JSONEncoder().encode(self) else {
			return Data()
		}
		
		return data
	}
	
	static var transferRepresentation: some TransferRepresentation {
		DataRepresentation(exportedContentType: .json) { envVar in
			envVar.data()
		}
		
		CodableRepresentation(contentType: .json)
	}
}
