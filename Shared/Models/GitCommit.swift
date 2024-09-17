//
//  GitCommit.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 02/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

protocol GitCommit: Decodable {
	var provider: GitSVNProvider { get }
	var commitSha: String { get }
	var commitMessage: String { get }
	var commitRef: String { get }
	var commitAuthorName: String { get }
	var commitUrl: URL { get }
	var org: String { get }
	var repo: String { get }
	var repoId: String { get }
	var deployHookId: String? { get }
	var deployHookName: String? { get }
	var deployHookRef: String? { get }
}

extension GitCommit {
	var commitUrl: URL {
		switch provider {
		case .github:
			return URL(string: "https://github.com/\(org)/\(repo)/commit/\(commitSha)")!
		case .gitlab:
			return URL(string: "https://gitlab.com/\(org)/\(repo)/-/commit/\(commitSha)")!
		case .bitbucket:
			return URL(string: "https://bitbucket.com/\(org)/\(repo)/commits/\(commitSha)")!
		}
	}

	var shortSha: String { String(commitSha.prefix(8)) }

	var commitMessageSummary: String {
		commitMessage.components(separatedBy: "\n").first ?? "(Empty Commit Message)"
	}
}

struct GitHubCommit: Codable, GitCommit {
	let commitSha: String
	let commitMessage: String
	let commitAuthorName: String
	let commitRef: String
	let org: String
	let repo: String
	let repoId: String
	let deployHookId: String?
	let deployHookName: String?
	let deployHookRef: String?

	var provider: GitSVNProvider { .github }

	enum CodingKeys: String, CodingKey {
		case commitSha = "githubCommitSha"
		case commitMessage = "githubCommitMessage"
		case commitAuthorName = "githubCommitAuthorName"
		case commitRef = "githubCommitRef"
		case org = "githubCommitOrg"
		case repo = "githubCommitRepo"
		case repoId = "githubCommitRepoId"
		case deployHookName, deployHookRef, deployHookId
	}
}

struct GitLabCommit: Codable, GitCommit {
	var provider: GitSVNProvider { .gitlab }
	let commitSha: String
	let commitMessage: String
	let commitAuthorName: String
	let commitRef: String
	var org: String { projectPath.components(separatedBy: "/")[0] }
	var repo: String { projectPath.components(separatedBy: "/")[1] }
	let repoId: String
	let deployHookId: String?
	let deployHookName: String?
	let deployHookRef: String?

	private let projectPath: String

	enum CodingKeys: String, CodingKey {
		case commitSha = "gitlabCommitSha"
		case commitMessage = "gitlabCommitMessage"
		case commitAuthorName = "gitlabCommitAuthorName"
		case commitRef = "gitlabCommitRef"
		case projectPath = "gitlabProjectPath"
		case repoId = "gitlabProjectId"
		case deployHookName, deployHookRef, deployHookId
	}
}

struct BitBucketCommit: Codable, GitCommit {
	var provider: GitSVNProvider { .bitbucket }
	let commitSha: String
	let commitMessage: String
	let commitAuthorName: String
	let commitRef: String
	let repoId: String
	let workspaceId: String
	let org: String
	let repo: String
	let deployHookId: String?
	let deployHookName: String?
	let deployHookRef: String?

	enum CodingKeys: String, CodingKey {
		case commitSha = "bitbucketCommitSha"
		case commitMessage = "bitbucketCommitMessage"
		case commitAuthorName = "bitbucketCommitAuthorName"
		case commitRef = "bitbucketCommitRef"
		case org = "bitbucketRepoOwner"
		case repo = "bitbucketRepoSlug"
		case repoId = "bitbucketRepoUuid"
		case workspaceId = "bitbucketRepoWorkspaceUuid"
		case deployHookName, deployHookRef, deployHookId
	}
}

struct AnyCommit: Codable, GitCommit {
	var wrapped: GitCommit

	var provider: GitSVNProvider { wrapped.provider }
	var commitSha: String { wrapped.commitSha }
	var commitMessage: String { wrapped.commitMessage }
	var commitAuthorName: String { wrapped.commitAuthorName }
	var commitRef: String { wrapped.commitRef }
	var org: String { wrapped.org }
	var repo: String { wrapped.repo }
	var repoId: String { wrapped.repoId }
	var deployHookId: String? { wrapped.deployHookId }
	var deployHookName: String? { wrapped.deployHookName }
	var deployHookRef: String? { wrapped.deployHookRef }
	
	var action: Action?
	var originalDeploymentId: VercelDeployment.ID?
	
	enum CodingKeys: CodingKey {
		case action, originalDeploymentId
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)
		
		if let githubCommit = try? GitHubCommit(from: decoder) {
			wrapped = githubCommit
		} else if let gitlabCommit = try? GitLabCommit(from: decoder) {
			wrapped = gitlabCommit
		} else if let bitbucketCommit = try? BitBucketCommit(from: decoder) {
			wrapped = bitbucketCommit
		} else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode commit"))
		}
		
		action = try? container.decodeIfPresent(Action.self, forKey: .action)
		originalDeploymentId = try? container.decodeIfPresent(VercelDeployment.ID.self, forKey: .originalDeploymentId)
	}
}

extension AnyCommit {
	enum Action: String, Codable {
		case promote
	}
}
