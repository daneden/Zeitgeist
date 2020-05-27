//
//  FetchVercelTeams.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 27/05/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import Cocoa

struct VercelTeamsAPIResponse: Decodable {
  public var teams: [VercelTeam] = [VercelTeam]()
}

struct VercelTeam: Decodable {
  public var id: String
  public var name: String
}

class FetchVercelTeams: ObservableObject {
  @Published var response: VercelTeamsAPIResponse = VercelTeamsAPIResponse() {
    didSet {
      self.objectWillChange.send()
    }
  }
  
  init() {
    let appDelegate = NSApplication.shared.delegate as? AppDelegate
    
    var request = URLRequest(url: URL(string: "https://api.vercel.com/v1/teams")!)
    request.allHTTPHeaderFields = appDelegate?.getVercelHeaders()
    URLSession.shared.dataTask(with: request) { (data, _, error) in
      do {
        let decodedData = try JSONDecoder().decode(VercelTeamsAPIResponse.self, from: data!)
        DispatchQueue.main.async {
          self.response = decodedData
        }
      } catch {
        print("Error")
        print(error.localizedDescription)
      }
    }.resume()
  }
}
