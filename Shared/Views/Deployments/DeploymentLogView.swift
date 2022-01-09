//
//  DeploymentLogView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 09/01/2022.
//

import SwiftUI

struct LogEvent: Codable, Identifiable {
  enum EventType: String, Codable {
    case command, stderr, stdout, deploymentState, delimiter, exit
  }
  
  struct Payload: Codable {
    var id: String
    var text: String?
    var date: TimeInterval
    var statusCode: Int?
  }
  
  var type: EventType
  var payload: Payload
  
  var id: String { payload.id }
  var date: Date { Date(timeIntervalSince1970: payload.date / 1000) }
  var text: String { payload.text ?? type.rawValue }
  
  var outputColor: Color {
    switch type {
    case .stderr:
      if text.localizedCaseInsensitiveContains("warn") {
        return .orange
      } else {
        return .red
      }
    default:
      return .primary
    }
  }
}

struct DeploymentLogView: View {
  @State private var logEvents: [LogEvent] = []
  
  var deployment: Deployment
  var accountID: Account.ID
  var body: some View {
    ScrollView([.vertical, .horizontal]) {
      LazyVStack(alignment: .leading, spacing: 0) {
        ForEach(logEvents) { event in
          ZStack {
            if event.type == .stderr {
              Color.clear
                .background(.quaternary)
            }
            
            HStack(alignment: .firstTextBaseline) {
              Text(event.date, style: .time)
                .foregroundStyle(.secondary)
              
              Text(event.text)
                .fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(.primary)
              
              Spacer(minLength: 0)
            }
            .padding(.horizontal)
            .padding(.vertical, 2)
          }
          .foregroundStyle(event.outputColor)
        }
      }
      .font(.footnote.monospaced())
    }
    .padding(.bottom)
    .navigationTitle("Build Logs")
    .task {
      let queryItems: [URLQueryItem] = [
        URLQueryItem(name: "follow", value: "1"),
        URLQueryItem(name: "limit", value: "-1"),
      ]
      
      guard let request = try? VercelAPI.request(
        for: .deployments(version: 2, deploymentID: deployment.id, path: "events"),
        with: accountID,
        queryItems: queryItems
      ) else {
        return
      }
      
      do {
        let (data, _) = try await URLSession.shared.bytes(for: request)
        
        for try await line in data.lines {
          if let lineAsData = line.data(using: .utf8),
             let event = try? JSONDecoder().decode(LogEvent.self, from: lineAsData) {
            logEvents.append(event)
          }
        }
      } catch {
        print(error.localizedDescription)
      }
    }
  }
}

//struct DeploymentLogView_Previews: PreviewProvider {
//    static var previews: some View {
//      DeploymentLogView(deployment: )
//    }
//}
