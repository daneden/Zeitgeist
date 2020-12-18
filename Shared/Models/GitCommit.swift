//
//  GitCommit.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 02/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

enum GitSVNProvider: String {
  case bitbucket, github, gitlab
}

let commitURLPattern: [GitSVNProvider: String] = [
  .bitbucket: "https://bitbucket.com/%@/%@/commits/%@",
  .github: "https://github.com/%@/%@/commit/%@",
  .gitlab: "https://gitlab.com/%@/%@/-/commit/%@"
]

protocol Commit {
  var provider: GitSVNProvider { get }
  var commitSha: String { get }
  var commitMessage: String { get }
  var commitAuthorName: String { get }
  var repo: String { get }
  var org: String { get }
}

struct AnyCommit: Commit, Decodable {
  private var wrapped: Commit
  
  init(from decoder: Decoder) throws {
    if let commit = try? BitBucketCommit(from: decoder) {
      wrapped = commit
    } else if let commit = try? GithubCommit(from: decoder) {
      wrapped = commit
    } else if let commit = try? GitlabCommit(from: decoder) {
      wrapped = commit
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: decoder.codingPath, debugDescription: ""))
    }
  }
  
  var provider: GitSVNProvider { wrapped.provider }
  var commitMessage: String { wrapped.commitMessage }
  var commitAuthorName: String { wrapped.commitAuthorName }
  var commitSha: String { wrapped.commitSha }
  var repo: String { wrapped.repo }
  var org: String { wrapped.org }
  
  var commitMessageSummary: String {
    return commitMessage.components(separatedBy: "\n").first ?? "(Empty Commit Message)"
  }
  
  var commitURL: URL? {
    let pattern = commitURLPattern[provider]!
    let string = String(format: pattern, org, repo, commitSha)
    return URL(string: string)
  }
  
  var shortSha: String {
    let index = commitSha.index(commitSha.startIndex, offsetBy: 7)
    return String(commitSha.prefix(upTo: index))
  }
}

struct BitBucketCommit: Decodable, Commit {
  var provider: GitSVNProvider { .bitbucket }
  var commitSha: String { bitbucketCommitSha }
  var repo: String { bitbucketRepoSlug }
  var org: String { bitbucketRepoOwner }
  var commitMessage: String { bitbucketCommitMessage }
  var commitAuthorName: String { bitbucketCommitAuthorName }
  
  var bitbucketCommitAuthorName: String
  var bitbucketCommitSha: String
  var bitbucketCommitMessage: String
  var bitbucketRepoSlug: String
  var bitbucketRepoOwner: String
}

struct GithubCommit: Decodable, Commit {
  var provider: GitSVNProvider { .github }
  var commitSha: String { githubCommitSha }
  var commitMessage: String { githubCommitMessage }
  var repo: String { githubCommitRepo }
  var org: String { githubCommitOrg }
  var commitAuthorName: String { githubCommitAuthorName }
  
  var githubCommitAuthorName: String
  var githubCommitSha: String
  var githubCommitMessage: String
  var githubCommitRepo: String
  var githubCommitOrg: String
}

struct GitlabCommit: Decodable, Commit {
  var provider: GitSVNProvider { .gitlab }
  var commitSha: String { gitlabCommitSha }
  var commitMessage: String { gitlabCommitMessage }
  var repo: String { gitlabProjectPath.components(separatedBy: "/")[1] }
  var org: String { gitlabProjectPath.components(separatedBy: "/")[0] }
  var commitAuthorName: String { gitlabCommitAuthorName }
  
  var gitlabCommitAuthorName: String
  var gitlabCommitSha: String
  var gitlabCommitMessage: String
  var gitlabProjectPath: String
}
