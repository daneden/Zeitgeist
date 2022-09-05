//
//  VercelAliasModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 12/07/2022.
//

import Foundation

struct VercelAlias: Codable, Hashable {
	var uid: String
	var alias: String
	var url: URL {
		URL(string: "https://\(alias)")!
	}

	enum CodingKeys: String, CodingKey {
		case uid, alias
	}
}

extension VercelAlias {
	struct APIResponse: Codable {
		var aliases: [VercelAlias]
	}
}
