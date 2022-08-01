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
  var commitAuthorName: String { get }
  var commitUrl: URL { get }
  var org: String { get }
  var repo: String { get }
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
  let org: String
  let repo: String
  let deployHookId: String?
  let deployHookName: String?
  let deployHookRef: String?
  
  var provider: GitSVNProvider { .github }
  
  enum CodingKeys: String, CodingKey {
    case commitSha = "githubCommitSha"
    case commitMessage = "githubCommitMessage"
    case commitAuthorName = "githubCommitAuthorName"
    case org = "githubCommitOrg"
    case repo = "githubCommitRepo"
    case deployHookName, deployHookRef, deployHookId
  }
}

struct GitLabCommit: Codable, GitCommit {
  var provider: GitSVNProvider { .gitlab }
  let commitSha: String
  let commitMessage: String
  let commitAuthorName: String
  var org: String { projectPath.components(separatedBy: "/")[0] }
  var repo: String { projectPath.components(separatedBy: "/")[1] }
  let deployHookId: String?
  let deployHookName: String?
  let deployHookRef: String?
  
  private let projectPath: String
  
  enum CodingKeys: String, CodingKey {
    case commitSha = "gitlabCommitSha"
    case commitMessage = "gitlabCommitMessage"
    case commitAuthorName = "gitlabCommitAuthorName"
    case projectPath = "gitlabProjectPath"
    case deployHookName, deployHookRef, deployHookId
  }
}

struct BitBucketCommit: Codable, GitCommit {
  var provider: GitSVNProvider { .bitbucket }
  let commitSha: String
  let commitMessage: String
  let commitAuthorName: String
  let org: String
  let repo: String
  let deployHookId: String?
  let deployHookName: String?
  let deployHookRef: String?
  
  enum CodingKeys: String, CodingKey {
    case commitSha = "bitbucketCommitSha"
    case commitMessage = "bitbucketCommitMessage"
    case commitAuthorName = "bitbucketCommitAuthorName"
    case org = "bitbucketRepoOwner"
    case repo = "bitbucketRepoSlug"
    case deployHookName, deployHookRef, deployHookId
  }
}

struct AnyCommit: Decodable, GitCommit {
  var wrapped: GitCommit
  
  var provider: GitSVNProvider { wrapped.provider }
  var commitSha: String { wrapped.commitSha }
  var commitMessage: String { wrapped.commitMessage }
  var commitAuthorName: String { wrapped.commitAuthorName }
  var org: String { wrapped.org }
  var repo: String { wrapped.repo }
  var deployHookId: String? { wrapped.deployHookId }
  var deployHookName: String? { wrapped.deployHookName }
  var deployHookRef: String? { wrapped.deployHookRef }
  
  init(from decoder: Decoder) throws {
    if let githubCommit = try? GitHubCommit(from: decoder) {
      wrapped = githubCommit
    } else if let gitlabCommit = try? GitLabCommit(from: decoder) {
      wrapped = gitlabCommit
    } else if let bitbucketCommit = try? BitBucketCommit(from: decoder) {
      wrapped = bitbucketCommit
    } else {
      throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode commit"))
    }
  }
}
