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
	var meta: DeploymentMeta?

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

	// MARK: - Computed Properties (Deployment Cause)

	var deploymentCause: DeploymentCause {
		guard let meta else { return .manual }

		if let action = meta.action {
			switch action {
			case .promote:
				return .promotion(originalDeploymentId: meta.originalDeploymentId)
			}
		} else if let deployHookName = meta.deployHookName {
			return .deployHook(name: deployHookName)
		} else if meta.hasCommitInfo {
			return .gitCommit(meta: meta)
		} else {
			return .manual
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

	// MARK: - CodingKeys
	//
	// Maps Swift property names to JSON keys.
	// Includes aliased keys for fields that differ between API endpoints.

	enum CodingKeys: String, CodingKey {
		// Aliased fields (different keys per endpoint)
		case id                         // single-deployment
		case uid                        // list-deployments
		case createdAt                  // single-deployment
		case created                    // list-deployments
		case state                      // list-deployments
		case readyState                 // single-deployment

		// Common fields
		case project = "name"
		case projectId
		case target
		case readySubstate
		case creator
		case team
		case teamId
		case meta
		case buildingAt
		case ready
		case url
		case inspectorUrl
	}

	// MARK: - Decodable (Manual)
	//
	// The Vercel API returns different keys depending on the endpoint:
	// - List deployments (/v6/deployments): uid, created, state
	// - Get single deployment (/v13/deployments/{id}): id, createdAt, readyState
	//
	// We use the KeyedDecodingContainer+Fallback extension to handle both formats.

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Decode aliased fields using fallback extension
		self.id = try container.decode(String.self, forKeys: .uid, .id)
		self.createdAt = try container.decode(Int.self, forKeys: .created, .createdAt)
		self.state = try container.decode(State.self, forKeys: .state, .readyState)

		// Direct mappings
		self.project = try container.decode(String.self, forKey: .project)
		self.projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
		self.target = try container.decodeIfPresent(Target.self, forKey: .target)
		self.readySubstate = try container.decodeIfPresent(ReadySubstate.self, forKey: .readySubstate)
		self.creator = try container.decodeIfPresent(CreatorOverview.self, forKey: .creator)
		self.team = try container.decodeIfPresent(TeamOverview.self, forKey: .team)
		self.teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
		self.buildingAt = try container.decodeIfPresent(Int.self, forKey: .buildingAt)
		self.ready = try container.decodeIfPresent(Int.self, forKey: .ready)
		self.url = try container.decode(String.self, forKey: .url)

		// Inspector URL with fallback to constructed URL
		if let inspectorUrl = try container.decodeIfPresent(String.self, forKey: .inspectorUrl) {
			self.inspectorUrl = inspectorUrl
		} else {
			self.inspectorUrl = "\(self.url)/_logs"
		}

		// Decode meta with graceful fallback to nil
		self.meta = try? container.decodeIfPresent(DeploymentMeta.self, forKey: .meta)
	}

	// MARK: - Encodable (Manual)
	//
	// We encode using the single-deployment format (id, createdAt, readyState)
	// since that's the canonical representation.

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		// Use single-deployment keys for encoding
		try container.encode(id, forKey: .id)
		try container.encode(createdAt, forKey: .createdAt)
		try container.encode(state, forKey: .readyState)

		// Common fields
		try container.encode(project, forKey: .project)
		try container.encodeIfPresent(projectId, forKey: .projectId)
		try container.encodeIfPresent(target, forKey: .target)
		try container.encodeIfPresent(readySubstate, forKey: .readySubstate)
		try container.encodeIfPresent(creator, forKey: .creator)
		try container.encodeIfPresent(team, forKey: .team)
		try container.encodeIfPresent(teamId, forKey: .teamId)
		try container.encodeIfPresent(meta, forKey: .meta)
		try container.encodeIfPresent(buildingAt, forKey: .buildingAt)
		try container.encodeIfPresent(ready, forKey: .ready)
		try container.encode(url, forKey: .url)
		try container.encode(inspectorUrl, forKey: .inspectorUrl)
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

	enum DeploymentCause: Codable, Equatable {
		case deployHook(name: String)
		case gitCommit(meta: DeploymentMeta)
		case promotion(originalDeploymentId: VercelDeployment.ID?)
		case manual

		var description: String {
			switch self {
			case .gitCommit(let meta): return meta.commitMessageSummary
			case .deployHook(let name): return name
			case .promotion: return "Production rebuild"
			case .manual: return "Manual deployment"
			}
		}

		var icon: String? {
			switch self {
			case .gitCommit(let meta): return meta.provider?.rawValue
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
		guard let meta, let provider = meta.provider else { return nil }

		var gitSource: [String: String?] = [
			"ref": meta.commitRef,
			"sha": meta.commitSha,
			"type": provider.rawValue,
		]

		var dataDict: [String: Any] = ["name": project]

		if target == .production {
			dataDict["target"] = "production"
		}

		switch provider {
		case .github:
			gitSource["repoId"] = meta.repoId
			gitSource["prId"] = nil
		case .bitbucket:
			gitSource["owner"] = meta.org
			gitSource["slug"] = meta.repo
			gitSource["workspaceUuid"] = meta.workspaceId
			gitSource["repoUuid"] = meta.repoId
		case .gitlab:
			gitSource["projectId"] = meta.repoId
		}

		dataDict["gitSource"] = gitSource
		return try? JSONSerialization.data(withJSONObject: dataDict)
	}
}
