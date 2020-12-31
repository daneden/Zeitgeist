//
//  ExampleDeployment.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 18/12/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation

struct ExampleDeployment {
  var deployment: Deployment?
  
  init() {
    if let path = Bundle.main.path(forResource: "exampleDeployment", ofType: "json") {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let result = try JSONDecoder().decode(Deployment.self, from: data)
        deployment = result
      } catch {
        deployment = nil
      }
    }
  }
}

struct ExampleProject {
  var project: Project?
  
  init() {
    if let path = Bundle.main.path(forResource: "exampleProject", ofType: "json") {
      do {
        let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        let result = try JSONDecoder().decode(Project.self, from: data)
        project = result
      } catch {
        project = nil
      }
    }
  }
}
