import Foundation
import SwiftUI

struct VercelDeployment: Identifiable, Hashable, Codable, Equatable {
	// MARK: - Stored Properties

	var id: String
	var project: String
	var projectId: String?
	var target: Target?
	var state: State
	var readySubstate: ReadySubstate?
	var creator: CreatorOverview?
	var team: TeamOverview?
	var teamId: String?
	var meta: AnyCommit?

	private var createdAt: Int
	private var buildingAt: Int?
	private var ready: Int?
	private var url: String
	private var inspectorUrl: String

	// MARK: - Computed Properties (Dates)

	var created: Date {
		Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
	}

	var readyAt: Date? {
		guard let ready else { return nil }
		return Date(timeIntervalSince1970: TimeInterval(ready / 1000))
	}

	var building: Date? {
		guard let buildingAt else { return nil }
		return Date(timeIntervalSince1970: TimeInterval(buildingAt / 1000))
	}

	var updated: Date {
		if let ready {
			return Date(timeIntervalSince1970: TimeInterval(ready / 1000))
		}
		return created
	}

	// MARK: - Computed Properties (URLs)

	var deploymentURL: URL {
		URL(string: "https://\(url)")!
	}

	var inspectorURL: URL {
		URL(string: "https://\(inspectorUrl)")!
	}

	// MARK: - Computed Properties (Backwards Compatibility)

	/// Alias for `meta` - the commit/webhook info that triggered this deployment
	var commit: AnyCommit? { meta }

	var deploymentCause: DeploymentCause {
		guard let meta else { return .manual }

		if let action = meta.action {
			switch action {
			case .promote:
				return .promotion(originalDeploymentId: meta.originalDeploymentId)
			}
		} else if let deploymentHookName = meta.deployHookName {
			return .deployHook(name: deploymentHookName)
		} else {
			return .gitCommit(commit: meta)
		}
	}

	// MARK: - Hashable & Equatable

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(state)
	}

	static func == (lhs: VercelDeployment, rhs: VercelDeployment) -> Bool {
		lhs.id == rhs.id && lhs.state == rhs.state
	}

	// MARK: - CodingKeys (for auto-synthesized Encodable)
	//
	// Maps Swift property names to JSON keys.
	// Encodable is auto-synthesized using these keys.

	enum CodingKeys: String, CodingKey {
		case id
		case project = "name"
		case projectId
		case target
		case state = "readyState"
		case readySubstate
		case creator
		case team
		case teamId
		case meta
		case createdAt
		case buildingAt
		case ready
		case url
		case inspectorUrl
	}

	// MARK: - Decodable (Manual)
	//
	// The Vercel API returns different keys depending on the endpoint:
	// - List deployments: uid, created, state
	// - Get single deployment: id, createdAt, readyState
	//
	// We use RawAPIResponse to handle both formats, then normalize.

	init(from decoder: Decoder) throws {
		let raw = try RawAPIResponse(from: decoder)

		// Normalize aliased fields (prefer list-deployments keys, fall back to single-deployment keys)
		guard let id = raw.uid ?? raw.id else {
			throw DecodingError.keyNotFound(
				CodingKeys.id,
				DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Neither 'uid' nor 'id' found")
			)
		}
		self.id = id

		guard let createdAt = raw.created ?? raw.createdAt else {
			throw DecodingError.keyNotFound(
				CodingKeys.createdAt,
				DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Neither 'created' nor 'createdAt' found")
			)
		}
		self.createdAt = createdAt

		guard let state = raw.state ?? raw.readyState else {
			throw DecodingError.keyNotFound(
				CodingKeys.state,
				DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Neither 'state' nor 'readyState' found")
			)
		}
		self.state = state

		// Direct mappings
		self.project = raw.name
		self.projectId = raw.projectId
		self.target = raw.target
		self.readySubstate = raw.readySubstate
		self.creator = raw.creator
		self.team = raw.team
		self.teamId = raw.teamId
		self.buildingAt = raw.buildingAt
		self.ready = raw.ready
		self.url = raw.url
		self.inspectorUrl = raw.inspectorUrl ?? "\(raw.url)/_logs"

		// Decode meta separately - it may have different structures across endpoints,
		// so we gracefully fall back to nil if it can't be decoded as AnyCommit
		let container = try decoder.container(keyedBy: CodingKeys.self)
		self.meta = try? container.decodeIfPresent(AnyCommit.self, forKey: .meta)
	}

	/// Raw API response structure that handles both endpoint formats.
	/// All aliased fields are optional; normalization happens in init(from:).
	/// Note: `meta` is excluded here and decoded separately with failure tolerance.
	private struct RawAPIResponse: Decodable {
		// Aliased fields (different keys per endpoint)
		let uid: String?        // list-deployments
		let id: String?         // single-deployment
		let created: Int?       // list-deployments
		let createdAt: Int?     // single-deployment
		let state: State?       // list-deployments
		let readyState: State?  // single-deployment

		// Common fields (same keys across endpoints)
		let name: String
		let projectId: String?
		let target: Target?
		let readySubstate: ReadySubstate?
		let creator: CreatorOverview?
		let team: TeamOverview?
		let teamId: String?
		let buildingAt: Int?
		let ready: Int?
		let url: String
		let inspectorUrl: String?
	}

	// MARK: - Mock Initializer

	init(asMockDeployment: Bool) throws {
		guard asMockDeployment else {
			throw DeploymentError.MockDeploymentInitError
		}

		id = "dpl_mock_\(UUID().uuidString.prefix(8))"
		project = "Example Project"
		projectId = UUID().uuidString
		state = .allCases.randomElement()!
		url = "zeitgeist-mock.vercel.app"
		inspectorUrl = "zeitgeist-mock.vercel.app/_logs"
		createdAt = Int(Date().timeIntervalSince1970 * 1000)
		target = .staging
		creator = CreatorOverview(uid: UUID().uuidString, username: "Test Account", githubLogin: nil)
		meta = nil
		readySubstate = nil
		team = nil
		teamId = nil
		buildingAt = nil
		ready = nil
	}

	enum DeploymentError: Error {
		case MockDeploymentInitError
	}
}

// MARK: - Nested Types

extension VercelDeployment {
	enum State: String, Codable, CaseIterable {
		case ready = "READY"
		case queued = "QUEUED"
		case error = "ERROR"
		case building = "BUILDING"
		case normal = "NORMAL"
		case offline = "OFFLINE"
		case cancelled = "CANCELED"
		case initializing = "INITIALIZING"

		static var typicalCases: [State] {
			allCases.filter { $0 != .normal && $0 != .offline && $0 != .initializing }
		}

		var description: LocalizedStringKey {
			switch self {
			case .error: return "Error building"
			case .building: return "Building"
			case .ready: return "Deployed"
			case .queued: return "Queued"
			case .cancelled: return "Cancelled"
			case .offline: return "Offline"
			default: return "Ready"
			}
		}
	}

	enum ReadySubstate: String, Codable, CaseIterable {
		case staged = "STAGED"
		case rolling = "ROLLING"
		case promoted = "PROMOTED"
	}

	enum Target: String, Codable, CaseIterable {
		case production, staging

		var description: LocalizedStringKey {
			switch self {
			case .production: return "Production"
			case .staging: return "Staging"
			}
		}
	}

	enum DeploymentCause: Codable {
		case deployHook(name: String)
		case gitCommit(commit: AnyCommit)
		case promotion(originalDeploymentId: VercelDeployment.ID?)
		case manual

		var description: String {
			switch self {
			case .gitCommit(let commit): return commit.commitMessageSummary
			case .deployHook(let name): return name
			case .promotion: return "Production rebuild"
			case .manual: return "Manual deployment"
			}
		}

		var icon: String? {
			switch self {
			case .gitCommit(let commit): return commit.provider.rawValue
			case .deployHook: return "hook"
			case .promotion: return "arrow.up.circle"
			case .manual: return nil
			}
		}
	}
}

// MARK: - Creator & Team

extension VercelDeployment {
	struct CreatorOverview: Codable, Identifiable {
		var id: ID { uid }
		let uid: String
		let username: String
		let githubLogin: String?
	}

	struct TeamOverview: Codable, Identifiable {
		let id: String
		let name: String?
		let slug: String
	}

	var unwrappedTeamId: String? {
		teamId ?? team?.id
	}
}

// MARK: - API Response Wrapper

extension VercelDeployment {
	struct APIResponse: Decodable {
		let deployments: [VercelDeployment]
		let pagination: Pagination?
	}
}

// MARK: - State UI Extensions

extension VercelDeployment.State {
	var imageName: String {
		switch self {
		case .error: return "exclamationmark.triangle"
		case .queued: return "square.stack.3d.up"
		case .building: return "timer"
		case .ready: return "checkmark.circle"
		case .cancelled: return "nosign"
		case .offline: return "wifi.slash"
		default: return "arrowtriangle.up.circle"
		}
	}

	var color: Color {
		switch self {
		case .error: return .red
		case .building: return .purple
		case .ready: return .green
		case .cancelled: return .primary
		default: return .gray
		}
	}
}

// MARK: - API Payloads

extension VercelDeployment {
	var promoteToProductionDataPayload: Data? {
		let dataDict: [String: Any] = [
			"deploymentId": id,
			"meta": ["action": "promote"],
			"name": project,
			"target": "production"
		]
		return try? JSONSerialization.data(withJSONObject: dataDict)
	}

	var redeployDataPayload: Data? {
		guard let meta else { return nil }

		var gitSource: [String: String?] = [
			"ref": meta.commitRef,
			"sha": meta.commitSha,
			"type": meta.provider.rawValue,
		]

		var dataDict: [String: Any] = ["name": project]

		if target == .production {
			dataDict["target"] = "production"
		}

		switch meta.provider {
		case .github:
			gitSource["repoId"] = meta.repoId
			gitSource["prId"] = nil
		case .bitbucket:
			gitSource["owner"] = meta.org
			gitSource["slug"] = meta.repo
			gitSource["workspaceUuid"] = (meta.wrapped as? BitBucketCommit)?.workspaceId
			gitSource["repoUuid"] = meta.repoId
		case .gitlab:
			gitSource["projectId"] = meta.repoId
		}

		dataDict["gitSource"] = gitSource
		return try? JSONSerialization.data(withJSONObject: dataDict)
	}
}
