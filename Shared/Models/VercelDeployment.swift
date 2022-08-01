import Foundation
import SwiftUI

struct VercelDeployment: Identifiable, Hashable, Decodable {
  var isMockDeployment: Bool?
  var project: String
  var id: String
  var target: Target?
  private var createdAt: Int = Int(Date().timeIntervalSince1970) / 1000
  
  var created: Date {
    return Date(timeIntervalSince1970: TimeInterval(createdAt / 1000))
  }
  
  var state: State
  private var urlString: String = "vercel.com"
  private var inspectorUrlString: String = "vercel.com"
  
  var url: URL {
    URL(string: "https://\(urlString)")!
  }
  
  var inspectorUrl: URL {
    URL(string: "https://\(inspectorUrlString)")!
  }
  
  var creator: Creator
  var commit: AnyCommit?
  
  var deploymentCause: DeploymentCause {
    guard let commit = commit else { return .manual }

    if let deploymentHookName = commit.deployHookName {
      return .deployHook(name: deploymentHookName)
    } else {
      return .gitCommit(commit: commit)
    }
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
    case commit = "meta"
    case inspectorUrlString = "inspectorUrl"
    
    case state, creator, target, readyState, uid, id
  }
  
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    project = try container.decode(String.self, forKey: .project)
    state = try container.decodeIfPresent(VercelDeployment.State.self, forKey: .readyState) ?? container.decode(VercelDeployment.State.self, forKey: .state)
    urlString = try container.decode(String.self, forKey: .urlString)
    createdAt = try container.decodeIfPresent(Int.self, forKey: .createdAtFallback) ?? container.decode(Int.self, forKey: .createdAt)
    id = try container.decodeIfPresent(String.self, forKey: .uid) ?? container.decode(String.self, forKey: .id)
    commit = try? container.decode(AnyCommit.self, forKey: .commit)
    creator = try container.decode(VercelDeployment.Creator.self, forKey: .creator)
    target = try? container.decode(VercelDeployment.Target.self, forKey: .target)
    inspectorUrlString = try container.decodeIfPresent(String.self, forKey: .inspectorUrlString) ?? "\(urlString)/_logs"
  }
  
  static func == (lhs: VercelDeployment, rhs: VercelDeployment) -> Bool {
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
    creator = VercelDeployment.Creator(uid: "0000", username: "zeitgeist", email: "dan.eden@me.com")
    target = VercelDeployment.Target.staging
  }
  
  enum DeploymentError: Error {
    case MockDeploymentInitError
  }
}

extension VercelDeployment {
  struct Creator: Codable, Identifiable {
    var uid: String
    var username: String
    var email: String
    
    var id: String {
      return uid
    }
  }
  
  enum State: String, Codable, CaseIterable {
    case ready = "READY"
    case queued = "QUEUED"
    case error = "ERROR"
    case building = "BUILDING"
    case normal = "NORMAL"
    case offline = "OFFLINE"
    case cancelled = "CANCELED"
    
    static var typicalCases: [VercelDeployment.State] {
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
  
  enum DeploymentCause {
    case deployHook(name: String)
    case gitCommit(commit: AnyCommit)
    case manual
    
    var description: String {
      switch self {
      case .gitCommit(let commit):
        return "\(commit.commitMessageSummary)"
      case .deployHook(let name):
        return "Ė \(name)"
      case .manual:
        return "Manual deployment"
      }
    }
    
    var icon: String? {
      switch self {
      case .gitCommit(let commit):
        return commit.provider.rawValue
      case .deployHook(_):
        return "hook"
      case .manual:
        return nil
      }
    }
  }
  
  enum Target: String, Codable, CaseIterable {
    case production, staging
  }
}

extension VercelDeployment {
  struct APIResponse: Decodable {
    let deployments: [VercelDeployment]
    let pagination: Pagination?
  }
}

extension VercelDeployment {
  func openDeploymentURL() {
    EnvironmentValues().openURL(url)
  }
  
  func openLogsURL() {
    EnvironmentValues().openURL(inspectorUrl)
  }
  
  func copyUrl() {
#if os(iOS)
    let pasteboard = UIPasteboard.general
    pasteboard.string = url.absoluteString
#else
    let pasteboard = NSPasteboard.general
    pasteboard.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
    pasteboard.setString(url.absoluteString, forType: NSPasteboard.PasteboardType.string)
#endif
  }
}
