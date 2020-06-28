//
//  FetchLatestRelease.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Version

struct GitHubRelease: Decodable {
  public var url: String
  public var html_url: String
  public var tag_name: String
  public var draft: Bool
  public var prerelease: Bool
  
  public var currentRelease: String {
    return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
  }
  
  public var isNewerThanCurrentBuild: Bool {
    let release: Version
    
    do {
      try release = Version(String(tag_name.split(separator: "v").last ?? "0.0.0") as String)
      return try release > Version(currentRelease)
    } catch {
      print("Unable to compare versions: target release threw an error")
      return false
    }
  }
}

class GitHubReleaseFetcher: ObservableObject {
  @Published var latestRelease: GitHubRelease?
  
  func load() {
    let url = URL(string: "https://api.github.com/repos/daneden/Zeitgeist/releases/latest")!
    URLSession.shared.dataTask(with: url) {(data, _, error) in
      do {
        if let responseData = data {
          let decodedData = try JSONDecoder().decode(GitHubRelease.self, from: responseData)
          DispatchQueue.main.async {
            self.latestRelease = decodedData
          }
        } else {
          print("No data returned from fetch")
        }
      } catch {
        print("Error on fetch")
        print(error.localizedDescription)
      }
    }.resume()
  }
  
  init() {
    load()
  }
}
