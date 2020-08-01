//
//  WidgetContent.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import WidgetKit
import SwiftUI

struct WidgetContent: TimelineEntry, Codable {
  var date = Date()
  let title: String
  let author: String
  let project: String
  let status: VercelDeploymentState
}

func deploymentToWidget(_ deployment: VercelDeployment) -> WidgetContent {
  let title = deployment.meta.githubCommitMessage ?? "Manual Deployment"
  let author = deployment.meta.githubCommitAuthorLogin ?? deployment.creator.username
  return WidgetContent(
    date: deployment.timestamp,
    title: title,
    author: author,
    project: deployment.name,
    status: deployment.state
  )
}

func readContents() -> [WidgetContent] {
  var contents: [WidgetContent] = []
  let archiveURL =
    FileManager.sharedContainerURL()
      .appendingPathComponent("contents.json")
  print(">>> \(archiveURL)")

  let decoder = JSONDecoder()
  if let codeData = try? Data(contentsOf: archiveURL) {
    do {
      contents = try decoder.decode([WidgetContent].self, from: codeData)
    } catch {
      print("Error: Can't decode contents")
    }
  }
  return contents
}
