import Foundation
import SwiftUI

struct VercelDeployment: Identifiable, Hashable, Decodable, Equatable {
	var isMockDeployment: Bool?
	var project: String
	var projectId: String?
	var id: String
	var target: Target?
	
	private var createdAt: Int = .init(Date().timeIntervalSince1970) / 1000
	private var buildingAt: Int?
	private var ready: Int?
	
	var readyAt: Date? {
		guard let ready else { return nil }
		return Date(timeIntervalSince1970: TimeInterval(ready / 1000))
	}
	
	var building: Date? {
		guard let buildingAt else { return nil }
		return Date(timeIntervalSince1970: TimeInterval(buildingAt / 1000))
	}

	var created: Date {
		return Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
	}
	
	var updated: Date {
		if let ready = ready {
			return Date(timeIntervalSince1970: TimeInterval(ready / 1000))
		} else {
			return created
		}
	}

	var state: State
	var readySubstate: ReadySubstate?
	
	private var urlString: String = "vercel.com"
	private var inspectorUrlString: String = "vercel.com"

	var url: URL {
		URL(string: "https://\(urlString)")!
	}

	var inspectorUrl: URL {
		URL(string: "https://\(inspectorUrlString)")!
	}

	var commit: AnyCommit?
	var creator: CreatorOverview?
	var team: TeamOverview?
	var teamId: String?

	var deploymentCause: DeploymentCause {
		guard let commit = commit else { return .manual }

		if let action = commit.action {
			switch action {
			case .promote:
				return .promotion(originalDeploymentId: commit.originalDeploymentId)
			}
		} else if let deploymentHookName = commit.deployHookName {
			return .deployHook(name: deploymentHookName)
		} else {
			return .gitCommit(commit: commit)
		}
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(state)
	}

	// MARK: - Coding Keys
	//
	// The Vercel API returns different keys depending on the endpoint:
	// - List deployments: uid, created, state
	// - Get single deployment: id, createdAt, readyState
	//
	// We use fallback decoding to handle both response formats.

	enum CodingKeys: String, CodingKey {
		// Primary keys (from single deployment endpoint)
		case id
		case createdAt
		case readyState

		// Fallback keys (from list deployments endpoint)
		case uid
		case created
		case state

		// Common keys
		case name  // maps to `project` property
		case projectId
		case url
		case meta  // maps to `commit` property
		case inspectorUrl
		case buildingAt
		case ready
		case readySubstate
		case target
		case creator
		case team
		case teamId
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		// Decode with fallbacks for API inconsistencies
		id = try container.decode(String.self, forKeys: .uid, .id)
		createdAt = try container.decode(Int.self, forKeys: .created, .createdAt)
		state = try container.decode(State.self, forKeys: .readyState, .state)

		// Standard decoding
		project = try container.decode(String.self, forKey: .name)
		projectId = try container.decodeIfPresent(String.self, forKey: .projectId)
		urlString = try container.decode(String.self, forKey: .url)
		buildingAt = try container.decodeIfPresent(Int.self, forKey: .buildingAt)
		ready = try container.decodeIfPresent(Int.self, forKey: .ready)
		readySubstate = try container.decodeIfPresent(ReadySubstate.self, forKey: .readySubstate)
		target = try container.decodeIfPresent(Target.self, forKey: .target)
		creator = try container.decodeIfPresent(CreatorOverview.self, forKey: .creator)
		team = try container.decodeIfPresent(TeamOverview.self, forKey: .team)
		teamId = try container.decodeIfPresent(String.self, forKey: .teamId)
		commit = try? container.decodeIfPresent(AnyCommit.self, forKey: .meta)
		inspectorUrlString = try container.decodeIfPresent(String.self, forKey: .inspectorUrl) ?? "\(urlString)/_logs"
	}

	static func == (lhs: VercelDeployment, rhs: VercelDeployment) -> Bool {
		return lhs.id == rhs.id && lhs.state == rhs.state
	}

	init(asMockDeployment: Bool) throws {
		guard asMockDeployment == true else {
			throw DeploymentError.MockDeploymentInitError
		}

		project = "Example Project"
		projectId = UUID().uuidString
		state = .allCases.randomElement()!
		urlString = "zeitgeist.daneden.me"
		createdAt = Int(Date().timeIntervalSince1970 * 1000)
		id = "0000"
		target = VercelDeployment.Target.staging
		creator = VercelDeployment.CreatorOverview(uid: UUID().uuidString, username: "Test Account", githubLogin: nil)
	}

	enum DeploymentError: Error {
		case MockDeploymentInitError
	}
}

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

		static var typicalCases: [VercelDeployment.State] {
			return Self.allCases.filter { state in
				state != .normal && state != .offline && state != .initializing
			}
		}

		var description: LocalizedStringKey {
			switch self {
			case .error:
				return "Error building"
			case .building:
				return "Building"
			case .ready:
				return "Deployed"
			case .queued:
				return "Queued"
			case .cancelled:
				return "Cancelled"
			case .offline:
				return "Offline"
			default:
				return "Ready"
			}
		}
	}
	
	enum ReadySubstate: String, Codable, CaseIterable {
		case staged = "STAGED", rolling = "ROLLING", promoted = "PROMOTED"
	}

	enum DeploymentCause: Codable {
		case deployHook(name: String)
		case gitCommit(commit: AnyCommit)
		case promotion(originalDeploymentId: VercelDeployment.ID?)
		case manual

		var description: String {
			switch self {
			case let .gitCommit(commit):
				return commit.commitMessageSummary
			case let .deployHook(name):
				return name
			case .promotion(_):
				return "Production rebuild"
			case .manual:
				return "Manual deployment"
			}
		}

		var icon: String? {
			switch self {
			case let .gitCommit(commit):
				return commit.provider.rawValue
			case .deployHook:
				return "hook"
			case .promotion(_):
				return "arrow.up.circle"
			case .manual:
				return nil
			}
		}
	}

	enum Target: String, Codable, CaseIterable {
		case production, staging
		
		var description: LocalizedStringKey {
			switch self {
			case .production:
				return "Production"
			case .staging:
				return "Staging"
			}
		}
	}
}

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

extension VercelDeployment {
	struct APIResponse: Decodable {
		let deployments: [VercelDeployment]
		let pagination: Pagination?
	}
}

extension VercelDeployment.State {
	var imageName: String {
		switch self {
		case .error:
			return "exclamationmark.triangle"
		case .queued:
			return "square.stack.3d.up"
		case .building:
			return "timer"
		case .ready:
			return "checkmark.circle"
		case .cancelled:
			return "nosign"
		case .offline:
			return "wifi.slash"
		default:
			return "arrowtriangle.up.circle"
		}
	}
	
	var color: Color {
		switch self {
		case .error:
			return .red
		case .building:
			return .purple
		case .ready:
			return .green
		case .cancelled:
			return .primary
		default:
			return .gray
		}
	}
}

extension VercelDeployment {
	var promoteToProductionDataPayload: Data? {
		let dataDict: [String: Any] = [
			"deploymentId": id,
			"meta": [
				"action": "promote"
			],
			"name": project,
			"target": "production"
		]
		
		return try? JSONSerialization.data(withJSONObject: dataDict)
	}
	
	var redeployDataPayload: Data? {
		guard let commit else {
			return nil
		}
		
		var gitSource: [String: String?] = [
			"ref": commit.commitRef,
			"sha": commit.commitSha,
			"type": commit.provider.rawValue,
		]
		
		var dataDict: [String: Any] = [
			"name": project
		]
		
		if target == .production {
			dataDict["target"] = "production"
		}
		
		switch commit.provider {
		case .github:
			gitSource["repoId"] = commit.repoId
			gitSource["prId"] = nil
		case .bitbucket:
			gitSource["owner"] = commit.org
			gitSource["slug"] = commit.repo
			gitSource["workspaceUuid"] = (commit.wrapped as? BitBucketCommit)?.workspaceId
			gitSource["repoUuid"] = commit.repoId
		case .gitlab:
			gitSource["projectId"] = commit.repoId
		}
		
		dataDict["gitSource"] = gitSource
		
		return try? JSONSerialization.data(withJSONObject: dataDict)
	}
}

extension VercelDeployment: Encodable {
	func encode(to encoder: any Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)

		// Use the single-deployment endpoint key names for consistency
		try container.encode(id, forKey: .id)
		try container.encode(createdAt, forKey: .createdAt)
		try container.encode(state, forKey: .readyState)

		try container.encode(project, forKey: .name)
		try container.encodeIfPresent(projectId, forKey: .projectId)
		try container.encode(urlString, forKey: .url)
		try container.encodeIfPresent(buildingAt, forKey: .buildingAt)
		try container.encodeIfPresent(ready, forKey: .ready)
		try container.encodeIfPresent(readySubstate, forKey: .readySubstate)
		try container.encodeIfPresent(target, forKey: .target)
		try container.encodeIfPresent(creator, forKey: .creator)
		try container.encodeIfPresent(team, forKey: .team)
		try container.encodeIfPresent(teamId, forKey: .teamId)
		try container.encodeIfPresent(commit, forKey: .meta)
		try container.encode(inspectorUrlString, forKey: .inspectorUrl)
	}
}
