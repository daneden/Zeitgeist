//
//  VercelDeployment.swift
//  ZeitgeistTests
//
//  Created by Daniel Eden on 02/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

let mockDeployment = VercelDeployment(
  id: "test-id",
  name: "placeholder-project",
  url: "https://vercel.com",
  created: 12345678,
  state: .building,
  creator: VercelDeploymentUser(
    id: "fake-id",
    email: "dan.eden@me.com",
    username: "daneden",
    githubLogin: "daneden"
  ),
  meta: VercelDeploymentMetadata(
    githubDeployment: "fake-deployment",
    githubOrg: "none",
    githubCommitRef: "ah4982jd",
    githubCommitRepo: "fake-repo",
    githubCommitSha: "ah4982jd",
    githubCommitMessage: "Commit new files",
    githubCommitAuthorLogin: "daneden",
    githubCommitAuthorName: "Daniel Eden"
  )
)
