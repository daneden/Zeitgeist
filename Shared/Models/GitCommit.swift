//
//  GitCommit.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 02/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

enum GitSVNProvider: String, Codable {
  case github, gitlab, bitbucket
}

struct GitCommit {
  var provider: GitSVNProvider? = nil
  var commitSha: String
  var commitMessage: String
  var commitAuthorName: String
  var commitURL: URL
  var repo: String
  
  var shortSha: String {
    let index = commitSha.index(commitSha.startIndex, offsetBy: 7)
    return String(commitSha.prefix(upTo: index))
  }
  
  var commitMessageSummary: String {
    return commitMessage.components(separatedBy: "\n").first ?? "(Empty Commit Message)"
  }
  
  static func from(json: [String: String]) -> GitCommit? {
    var builder = CommitBuilder()
    for(key, _ ) in json.prefix(1) {
      if key.hasPrefix("github") {
        builder = .init(provider: .github)
      } else if key.hasPrefix("bitbucket") {
        builder = .init(provider: .bitbucket)
      } else if key.hasPrefix("gitlab") {
        builder = .init(provider: .gitlab)
      }
    }
    
    return builder.build(from: json)
  }
}

class CommitBuilder {
  var provider: GitSVNProvider? = nil
  var repoKey: String?
  var namespaceKey: String?
  var urlPattern: String?
  
  init() {}
  
  init(provider: GitSVNProvider) {
    self.provider = provider
    
    switch provider {
    case .bitbucket:
      self.urlPattern = "https://bitbucket.com/%@/%@/commits/%@"
      self.repoKey = "RepoSlug"
      self.namespaceKey = "RepoOwner"
    case .github:
      self.urlPattern = "https://github.com/%@/%@/commit/%@"
      self.repoKey = "CommitRepo"
      self.namespaceKey = "CommitOrg"
    case .gitlab:
      self.urlPattern = "https://gitlab.com/%@/%@/-/commit/%@"
      self.repoKey = "ProjectNamespace"
      self.namespaceKey = "ProjectName"
    }
  }
  
  func pfx(_ val: String) -> String {
    return "\(provider!.rawValue)\(val)"
  }
  
  func build(from: [String: String]) -> GitCommit? {
    if provider == nil {
      return nil
    }
    
    let sha = from[pfx("CommitSha")] ?? ""
    let message = from[pfx("CommitMessage")] ?? ""
    let authorName = from[pfx("CommitAuthorName")] ?? ""
    let repo = from[pfx(repoKey!)] ?? ""
    let namespace = from[pfx(namespaceKey!)] ?? ""
    let url = String(format: urlPattern!, namespace, repo, sha)
    
    return GitCommit(
      provider: provider,
      commitSha: sha,
      commitMessage: message,
      commitAuthorName: authorName,
      commitURL: URL(string: url)!,
      repo: repo
    )
  }
}
