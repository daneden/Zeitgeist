//
//  ContentStore.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI
import Combine
import Foundation

extension FileManager {
  static func sharedContainerURL() -> URL {
    return FileManager.default.containerURL(
      forSecurityApplicationGroupIdentifier: "group.me.daneden.Zeitgeist.contents"
    )!
  }
}

func readContents() -> [WidgetContent] {
  var contents: [WidgetContent] = []
  let archiveURL =
    FileManager.sharedContainerURL()
      .appendingPathComponent("contents.json")
  // print(">>> \(archiveURL)")

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

func saveDeploymentsToDisk(deployments: [VercelDeployment]) {
  let widgetContents = deployments.map { deployment in
    deploymentToWidget(deployment)
  }
  
  let archiveURL = FileManager.sharedContainerURL().appendingPathComponent("contents.json")
  // print(">>> \(archiveURL)")
  let fileManager = FileManager()
  
  if fileManager.fileExists(atPath: "\(archiveURL)"){
    do {
      try fileManager.removeItem(atPath: "\(archiveURL)")
    } catch let error {
        print("Error removing cached entries file:\n \(error)")
    }
  }
  
  let encoder = JSONEncoder()
  if let dataToSave = try? encoder.encode(widgetContents) {
    do {
      try dataToSave.write(to: archiveURL)
    } catch {
      print("Error: Failed to write contents")
      return
    }
  }
}
