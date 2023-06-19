import Foundation
import SwiftUI

struct VercelDeployment: Identifiable, Hashable, Decodable {
	var isMockDeployment: Bool?
	var project: String
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
		return Date(timeIntervalSince1970: TimeInterval(buildingAt))
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

	enum CodingKeys: String, CodingKey {
		case project = "name"
		case urlString = "url"
		case createdAt = "created"
		case createdAtFallback = "createdAt"
		case commit = "meta"
		case inspectorUrlString = "inspectorUrl"
		case buildingAt = "buildingAt"

		case state, creator, target, readyState, ready, uid, id, teamId, team
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		project = try container.decode(String.self, forKey: .project)
		state = try container.decodeIfPresent(VercelDeployment.State.self, forKey: .readyState) ?? container.decode(VercelDeployment.State.self, forKey: .state)
		urlString = try container.decode(String.self, forKey: .urlString)
		createdAt = try container.decodeIfPresent(Int.self, forKey: .createdAtFallback) ?? container.decode(Int.self, forKey: .createdAt)
		buildingAt = try container.decodeIfPresent(Int.self, forKey: .buildingAt)
		id = try container.decodeIfPresent(String.self, forKey: .uid) ?? container.decode(String.self, forKey: .id)
		commit = try? container.decode(AnyCommit.self, forKey: .commit)
		target = try? container.decode(VercelDeployment.Target.self, forKey: .target)
		inspectorUrlString = try container.decodeIfPresent(String.self, forKey: .inspectorUrlString) ?? "\(urlString)/_logs"
		team = try? container.decodeIfPresent(TeamOverview.self, forKey: .team)
		teamId = try? container.decodeIfPresent(String.self, forKey: .teamId)
		creator = try container.decodeIfPresent(CreatorOverview.self, forKey: .creator)
		ready = try container.decodeIfPresent(Int.self, forKey: .ready)
	}

	static func == (lhs: VercelDeployment, rhs: VercelDeployment) -> Bool {
		return lhs.id == rhs.id && lhs.state == rhs.state
	}

	init(asMockDeployment: Bool) throws {
		guard asMockDeployment == true else {
			throw DeploymentError.MockDeploymentInitError
		}

		project = "Example Project"
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

		static var typicalCases: [VercelDeployment.State] {
			return Self.allCases.filter { state in
				state != .normal && state != .offline
			}
		}

		var description: String {
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

	enum DeploymentCause {
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
				return "Production Rebuild"
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
