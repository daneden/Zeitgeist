//
//  GitCommit.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 02/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//
//  NOTE: This file previously contained the GitCommit protocol and concrete
//  commit types (GitHubCommit, GitLabCommit, BitBucketCommit, AnyCommit).
//  These have been replaced by the unified DeploymentMeta struct which uses
//  automatic Codable synthesis. See DeploymentMeta.swift.
//
//  This file is kept for reference but may be removed in a future cleanup.
//

import Foundation

// The GitSVNProvider enum is defined in GitRepoModel.swift
// The DeploymentMeta struct in DeploymentMeta.swift replaces AnyCommit
