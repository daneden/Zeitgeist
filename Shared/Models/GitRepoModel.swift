//
//  GitRepoModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 08/07/2022.
//

import Foundation

enum GitSVNProvider: String, Codable {
  case bitbucket, github, gitlab
}

protocol GitRepo: Decodable {
  var type: GitSVNProvider? { get }
  var org: String? { get }
  var name: String? { get }
  var deployHooks: [GitDeployHook] { get }
  var updatedAt: Int? { get }
  var createdAt: Int? { get }
  var sourceless: Bool? { get }
  var productionBranch: String? { get }
  var gitCredentialId: String? { get }
}

extension GitRepo {
  var repoSlug: String? {
    if let org = org, let name = name {
      return "\(org)/\(name)"
    } else {
      return nil
    }
  }
  
  var repoUrl: URL? {
    guard let name = name,
          let org = org,
          let type = type else {
      return nil
    }

    switch type {
    case .github:
      return URL(string: "https://github.com/\(org)/\(name)/")
    case .gitlab:
      return URL(string: "https://gitlab.com/\(org)/\(name)/")
    case .bitbucket:
      return URL(string: "https://bitbucket.com/\(org)/\(name)/")
    }
    
  }
}

struct GitDeployHook: Identifiable, Codable {
  let createdAt: Int?
  let id: String
  let name: String
  let ref: String
  let url: URL
}

struct GitHubRepo: GitRepo, Codable {
  let org: String?
  let name: String?
  let type: GitSVNProvider?
  let deployHooks: [GitDeployHook]
  let createdAt: Int?
  let gitCredentialId: String?
  let sourceless: Bool?
  let updatedAt: Int?
  let productionBranch: String?
  
  enum CodingKeys: String, CodingKey {
    case org, type, deployHooks, gitCredentialId, updatedAt, createdAt, sourceless, productionBranch
    
    case name = "repo"
  }
}

struct GitLabRepo: GitRepo, Codable {
  let org: String?
  let name: String?
  let type: GitSVNProvider?
  let deployHooks: [GitDeployHook]
  let createdAt: Int?
  let gitCredentialId: String?
  let sourceless: Bool?
  let updatedAt: Int?
  let productionBranch: String?
  
  enum CodingKeys: String, CodingKey {
    case type, deployHooks, gitCredentialId, updatedAt, createdAt, sourceless, productionBranch
    
    case name = "projectName"
    case org = "projectNamespace"
  }
}

struct BitBucketRepo: GitRepo, Codable {
  let org: String?
  let name: String?
  let type: GitSVNProvider?
  let deployHooks: [GitDeployHook]
  let createdAt: Int?
  let gitCredentialId: String?
  let sourceless: Bool?
  let updatedAt: Int?
  let productionBranch: String?
  
  enum CodingKeys: String, CodingKey {
    case type, deployHooks, gitCredentialId, updatedAt, createdAt, sourceless, productionBranch
    case name = "slug"
    case org = "owner"
  }
}

struct VercelRepositoryLink: Decodable, GitRepo {
  private var wrapped: GitRepo
  
  var name: String? { wrapped.name }
  var type: GitSVNProvider? { wrapped.type }
  var sourceless: Bool? { wrapped.sourceless }
  var updatedAt: Int? { wrapped.updatedAt }
  var createdAt: Int? { wrapped.createdAt }
  var productionBranch: String? { wrapped.productionBranch }
  var gitCredentialId: String? { wrapped.gitCredentialId }
  var deployHooks: [GitDeployHook] { wrapped.deployHooks }
  var org: String? { wrapped.org }
  
  init(from decoder: Decoder) throws {
    if let githubDecoded = try? GitHubRepo(from: decoder) {
      wrapped = githubDecoded
    } else if let gitlabDecoded = try? GitLabRepo(from: decoder) {
      wrapped = gitlabDecoded
    } else if let bitbucketDecoded = try? BitBucketRepo(from: decoder) {
      wrapped = bitbucketDecoded
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode repository")
      )
    }
  }
}
