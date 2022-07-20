//
//  VercelDomain.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 20/07/2022.
//

import Foundation

struct VercelDomain: Codable {
  let name: String
  let apexName: String
  let projectId: String
  let redirect: String?
  let redirectStatusCode: Int?
  let gitBranch: String?
  let updatedAt: Int?
  let createdAt: Int?
  let verified: Bool
  let verification: [Verification]?
}

extension VercelDomain {
  struct Verification: Codable {
    let type: String
    let domain: String
    let value: String
    let reason: String
  }
  
  struct APIResponse: Codable {
    let domains: [VercelDomain]
    let pagination: Pagination?
  }
}
