//
//  AccountViewModel.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import Foundation

protocol Account: Decodable {
	var id: String { get }
	var name: String? { get }
	var avatar: String? { get }
	var username: String { get }
}

struct VercelAccount: Account, Codable, Identifiable {
	typealias ID = String

	private var wrapped: Account

	var id: ID { wrapped.id }
	var isTeam: Bool { id.isTeam }
	var avatar: String? { wrapped.avatar }
	var name: String? { wrapped.name }
	var username: String { wrapped.username }

	enum CodingKeys: String, CodingKey {
		case id, avatar, name, username
	}

	init(from decoder: Decoder) throws {
		// Accounts are encoded as direct values when encoded from VercelAccount, so we'll try decoding that first
		if let user = try? VercelUser(from: decoder) {
			wrapped = user
		} else
		// Otherwise, we may be decoding a response from /v2/user
		if let user = try? VercelUser.APIResponse(from: decoder).user {
			wrapped = user
		} else
		// Otherwise, we may be decoding a response from /v2/teams/{id}
		if let team = try? VercelTeam(from: decoder) {
			wrapped = team
		} else {
			throw DecodingError.dataCorrupted(
				DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode Vercel account.")
			)
		}
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.singleValueContainer()

		if let team = wrapped as? VercelTeam {
			try container.encode(team)
		} else if let user = wrapped as? VercelUser {
			try container.encode(user)
		} else {
			throw EncodingError.invalidValue(
				wrapped,
				EncodingError.Context(codingPath: encoder.codingPath,
				                      debugDescription: "Unable to encode Vercel account")
			)
		}
	}
}

extension VercelAccount: Hashable {
	static func == (lhs: VercelAccount, rhs: VercelAccount) -> Bool {
		lhs.hashValue == rhs.hashValue
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}

extension VercelAccount.ID {
	var isTeam: Bool {
		starts(with: "team_")
	}

	static var NullValue = "NULL"
}

private struct VercelUser: Account, Codable {
	var id: String
	var name: String?
	var avatar: String?
	var username: String
}

extension VercelUser {
	struct APIResponse: Codable {
		var user: VercelUser
	}
}

private struct VercelTeam: Account, Codable {
	var id: String
	var name: String?
	var avatar: String?
	var username: String

	enum CodingKeys: String, CodingKey {
		case id, name, avatar
		case username = "slug"
	}
}

// extension AccountViewModel {
//  func loadCachedData() -> VercelAccount? {
//    if let cachedResults = URLCache.shared.cachedResponse(for: request),
//       let decodedResults = handleResponseData(data: cachedResults.data, isTeam: accountId.isTeam) {
//      return decodedResults
//    }
//
//    return nil
//  }
// }
