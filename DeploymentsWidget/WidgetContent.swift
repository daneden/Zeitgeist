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
  let status: DeploymentState
}

func deploymentToWidget(_ deployment: Deployment) -> WidgetContent {
  let title = deployment.svnInfo?.commitMessageSummary ?? "Manual Deployment"
  let author = deployment.svnInfo?.commitAuthorName ?? deployment.creator.username
  return WidgetContent(
    date: deployment.createdAt,
    title: String(title),
    author: author,
    project: deployment.project,
    status: deployment.state
  )
}
