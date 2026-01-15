//
//  DeploymentMeta.swift
//  Zeitgeist
//
//  Unified struct for deployment metadata including git commit info,
//  deploy hooks, and promotion actions. Replaces the type-erased AnyCommit.
//

import Foundation

struct DeploymentMeta: Codable, Equatable, Hashable {
	// MARK: - Common Fields

	let deployHookId: String?
	let deployHookName: String?
	let deployHookRef: String?
	let action: Action?
	let originalDeploymentId: String?

	// MARK: - GitHub Fields

	private let githubCommitSha: String?
	private let githubCommitMessage: String?
	private let githubCommitAuthorName: String?
	private let githubCommitAuthorLogin: String?
	private let githubCommitRef: String?
	private let githubCommitOrg: String?
	private let githubCommitRepo: String?
	private let githubCommitRepoId: String?

	// MARK: - GitLab Fields

	private let gitlabCommitSha: String?
	private let gitlabCommitMessage: String?
	private let gitlabCommitAuthorName: String?
	private let gitlabCommitRef: String?
	private let gitlabProjectPath: String?
	private let gitlabProjectId: String?

	// MARK: - Bitbucket Fields

	private let bitbucketCommitSha: String?
	private let bitbucketCommitMessage: String?
	private let bitbucketCommitAuthorName: String?
	private let bitbucketCommitRef: String?
	private let bitbucketRepoOwner: String?
	private let bitbucketRepoSlug: String?
	private let bitbucketRepoUuid: String?
	private let bitbucketRepoWorkspaceUuid: String?
	private let bitbucketCommitAuthorAvatar: String?

	// MARK: - Computed Properties (Provider Detection)

	var provider: GitSVNProvider? {
		if githubCommitSha != nil { return .github }
		if gitlabCommitSha != nil { return .gitlab }
		if bitbucketCommitSha != nil { return .bitbucket }
		return nil
	}

	// MARK: - Computed Properties (Unified Access)

	var commitSha: String? {
		githubCommitSha ?? gitlabCommitSha ?? bitbucketCommitSha
	}

	var commitMessage: String? {
		githubCommitMessage ?? gitlabCommitMessage ?? bitbucketCommitMessage
	}

	var commitAuthorName: String? {
		githubCommitAuthorName ?? gitlabCommitAuthorName ?? bitbucketCommitAuthorName
	}

	var commitRef: String? {
		githubCommitRef ?? gitlabCommitRef ?? bitbucketCommitRef
	}

	var org: String? {
		if let githubOrg = githubCommitOrg {
			return githubOrg
		}
		if let gitlabPath = gitlabProjectPath {
			return gitlabPath.components(separatedBy: "/").first
		}
		return bitbucketRepoOwner
	}

	var repo: String? {
		if let githubRepo = githubCommitRepo {
			return githubRepo
		}
		if let gitlabPath = gitlabProjectPath {
			let components = gitlabPath.components(separatedBy: "/")
			return components.count > 1 ? components[1] : nil
		}
		return bitbucketRepoSlug
	}

	var repoId: String? {
		githubCommitRepoId ?? gitlabProjectId ?? bitbucketRepoUuid
	}

	var workspaceId: String? {
		bitbucketRepoWorkspaceUuid
	}

	// MARK: - Convenience Properties

	var hasCommitInfo: Bool {
		provider != nil
	}

	var hasDeployHookInfo: Bool {
		deployHookName != nil
	}

	var commitUrl: URL? {
		guard let provider, let org, let repo, let sha = commitSha else { return nil }

		switch provider {
		case .github:
			return URL(string: "https://github.com/\(org)/\(repo)/commit/\(sha)")
		case .gitlab:
			return URL(string: "https://gitlab.com/\(org)/\(repo)/-/commit/\(sha)")
		case .bitbucket:
			return URL(string: "https://bitbucket.com/\(org)/\(repo)/commits/\(sha)")
		}
	}

	var shortSha: String? {
		guard let sha = commitSha else { return nil }
		return String(sha.prefix(8))
	}

	var commitMessageSummary: String {
		guard let message = commitMessage else {
			return "(No commit message)"
		}
		return message.components(separatedBy: "\n").first ?? "(Empty commit message)"
	}
	
	var commitAuthorAvatarUrl: URL? {
		if let githubCommitAuthorLogin {
			return URL(string: "https://github.com/\(githubCommitAuthorLogin).png")
		} else if let bitbucketCommitAuthorAvatar {
			return URL(string: bitbucketCommitAuthorAvatar)
		} else {
			return nil
		}
	}

	// MARK: - Nested Types

	enum Action: String, Codable {
		case promote
	}
}
