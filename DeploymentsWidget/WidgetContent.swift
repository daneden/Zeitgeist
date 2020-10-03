//
//  WidgetContent.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import WidgetKit
import SwiftUI

struct WidgetContent: TimelineEntry, Codable, Hashable {
  var date = Date()
  let title: String
  let author: String
  let project: String
  let status: VercelDeploymentState
}

func deploymentToWidget(_ deployment: VercelDeployment) -> WidgetContent {
  let title = deployment.meta.githubCommitMessage?.split(separator: "\n")[0] ?? "Manual Deployment"
  let author = deployment.meta.githubCommitAuthorLogin ?? deployment.creator.username
  return WidgetContent(
    date: deployment.timestamp,
    title: String(title),
    author: author,
    project: deployment.name,
    status: deployment.state
  )
}
