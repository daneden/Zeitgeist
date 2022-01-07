import Foundation
import WidgetKit
import SwiftUI

struct DeploymentsResponse: Decodable {
  var deployments: [Deployment]
}

enum DeploymentTarget: String, Codable, CaseIterable {
  case production, staging
}

enum DeploymentState: String, Codable, CaseIterable {
  case ready = "READY"
  case queued = "QUEUED"
  case error = "ERROR"
  case building = "BUILDING"
  case normal = "NORMAL"
  case offline = "OFFLINE"
  case cancelled = "CANCELED"
  
  static var typicalCases: [DeploymentState] {
    return Self.allCases.filter { state in
      state != .normal && state != .offline
    }
  }
  
  var description: String {
    switch self {
    case .error:
      return "Error building"
    case .building:
      return "Building"
    case .ready:
      return "Deployed"
    case .queued:
      return "Queued"
    case .cancelled:
      return "Cancelled"
    case .offline:
      return "Offline"
    default:
      return "Ready"
    }
  }
}

struct DeploymentCreator: Codable, Identifiable {
  var uid: String
  var username: String
  var email: String
  
  var id: String {
    return uid
  }
}

struct Deployment: Identifiable, Hashable, TimelineEntry, Decodable {
  var isMockDeployment: Bool?
  var project: String
  var id: String
  var target: DeploymentTarget?
  private var createdAt: Int = Int(Date().timeIntervalSince1970) / 1000
  
  // `date` is required to conform to `TimelineEntry`
  var date: Date {
    return Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
  }
  
  var state: DeploymentState
  private var urlString: String = "vercel.com"
  
  var url: URL {
    URL(string: "https://\(urlString)")!
  }
  
  var creator: DeploymentCreator
  var commit: AnyCommit?
  
  var deploymentCause: String {
    commit?.commitMessageSummary ?? "Manual Deployment"
  }
  
  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(state)
  }
  
  enum CodingKeys: String, CodingKey {
    case project = "name"
    case urlString = "url"
    case createdAt = "created"
    case createdAtFallback = "createdAt"
    case id = "uid"
    case commit = "meta"
    
    case state, creator, target
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    project = try container.decode(String.self, forKey: .project)
    state = try container.decode(DeploymentState.self, forKey: .state)
    urlString = try container.decode(String.self, forKey: .urlString)
    createdAt = try container.decode(Int.self, forKey: .createdAt)
    id = try container.decode(String.self, forKey: .id)
    commit = try? container.decode(AnyCommit.self, forKey: .commit)
    creator = try container.decode(DeploymentCreator.self, forKey: .creator)
    target = try? container.decode(DeploymentTarget.self, forKey: .target)
  }
  
  static func == (lhs: Deployment, rhs: Deployment) -> Bool {
    return lhs.id == rhs.id && lhs.state == rhs.state
  }
  
  init(asMockDeployment: Bool) throws {
    guard asMockDeployment == true else {
      throw DeploymentError.MockDeploymentInitError
    }
    
    project = "Example Project"
    state = .allCases.randomElement()!
    urlString = "zeitgeist.daneden.me"
    createdAt = Int(Date().timeIntervalSince1970 * 1000)
    id = "0000"
    creator = DeploymentCreator(uid: "0000", username: "zeitgeist", email: "dan.eden@me.com")
    target = DeploymentTarget.staging
  }
  
  enum DeploymentError: Error {
    case MockDeploymentInitError
  }
}
