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
    for(key, _ ) in json.prefix(1) {
      if key.hasPrefix("github") {
        return buildGitHubCommit(from: json)
      } else if key.hasPrefix("bitbucket") {
        return buildBitBucketCommit(from: json)
      } else if key.hasPrefix("gitlab") {
        return buildGitLabCommit(from: json)
      }
    }
    
    return nil
  }
}

func buildGitHubCommit(from: [String: String]) -> GitCommit {
  func pfx(_ val: String) -> String {
    return "\(GitSVNProvider.github.rawValue)\(val)"
  }
  
  return GitCommit(
    provider: .github,
    commitSha: from[pfx("CommitSha")]!,
    commitMessage: from[pfx("CommitMessage")]!,
    commitAuthorName: from[pfx("CommitAuthorName")]!,
    commitURL: URL(string: "https://github.com/\(from[pfx("CommitOrg")]!)/\(from[pfx("CommitRepo")]!)/commit/\(from[pfx("CommitSha")]!)")!,
    repo: from[pfx("CommitRepo")]!
  )
}

func buildGitLabCommit(from: [String: String]) -> GitCommit {
  func pfx(_ val: String) -> String {
    return "\(GitSVNProvider.gitlab.rawValue)\(val)"
  }
  
  return GitCommit(
    provider: .gitlab,
    commitSha: from[pfx("CommitSha")]!,
    commitMessage: from[pfx("CommitMessage")]!,
    commitAuthorName: from[pfx("CommitAuthorName")]!,
    commitURL: URL(string: "https://gitlab.com/\(from[pfx("ProjectNamespace")]!)/\(from[pfx("ProjectName")]!)/-/commit/\(from[pfx("CommitSha")]!)")!,
    repo: from[pfx("ProjectName")]!
  )
}

func buildBitBucketCommit(from: [String: String]) -> GitCommit {
  func pfx(_ val: String) -> String {
    return "\(GitSVNProvider.bitbucket.rawValue)\(val)"
  }
  
  return GitCommit(
    provider: .bitbucket,
    commitSha: from[pfx("CommitSha")]!,
    commitMessage: from[pfx("CommitMessage")]!,
    commitAuthorName: from[pfx("CommitAuthorName")]!,
    commitURL: URL(string: "https://bitbucket.com/\(from[pfx("RepoOwner")]!)/\(from[pfx("RepoSlug")]!)/commits/\(from[pfx("CommitSha")]!)")!,
    repo: from[pfx("RepoName")]!
  )
}
