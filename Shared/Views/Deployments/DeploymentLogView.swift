//
//  DeploymentLogView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 09/01/2022.
//

import SwiftUI

struct LogEvent: Codable, Identifiable {
  enum EventType: String, Codable {
    case command, stderr, stdout, delimiter, exit
    //    case deploymentState = "deployment-state"
  }
  
  struct DeploymentStateInfo: Codable {
    var name: String
    var readyState: DeploymentState
  }
  
  struct Payload: Codable {
    var id: String
    var text: String
    var date: TimeInterval
    var statusCode: Int?
  }
  
  var type: EventType
  var payload: Payload
  
  var id: String { payload.id }
  var date: Date { Date(timeIntervalSince1970: payload.date / 1000) }
  var text: String { payload.text }
  
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

struct LogEventView: View {
  var event: LogEvent
  
  var body: some View {
    ZStack {
      if event.type == .stderr {
        Color.clear
          .background(.quaternary)
      }
      
      HStack(alignment: .firstTextBaseline) {
        Text(event.date, style: .time)
          .foregroundStyle(.secondary)
        
        if let text = event.text {
          Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(.primary)
        }
        
        Spacer(minLength: 0)
      }
      .padding(.horizontal)
      .padding(.vertical, 2)
    }
    .foregroundStyle(event.outputColor)
  }
}

struct DeploymentLogView: View {
  @State private var logEvents: [LogEvent] = []
  
  var deployment: Deployment
  var accountID: Account.ID
  var body: some View {
    ScrollViewReader { proxy in
      VStack(alignment: .leading, spacing: 0) {
        GeometryReader { geometry in
          ScrollView([.vertical, .horizontal]) {
            VStack(alignment: .leading, spacing: 0) {
              ForEach(logEvents) { event in
                LogEventView(event: event)
                  .id(event.id)
              }
            }
            .frame(minHeight: geometry.size.height, alignment: .topLeading)
            .font(.footnote.monospaced())
            .toolbar {
              ToolbarItem(placement: .navigationBarTrailing) {
                Link(destination: deployment.logsURL) {
                  Label("Open in Safari", systemImage: "safari")
                }
              }
              
              
              ToolbarItem(placement: .bottomBar) {
                if let latestEvent = logEvents.last {
                  Button(action: {
                    withAnimation {
                      proxy.scrollTo(latestEvent.id, anchor: .bottomLeading)
                    }
                  }) {
                    Label("Scroll to bottom", systemImage: "chevron.down.square")
                      .labelStyle(.titleAndIcon)
                      .font(.footnote)
                  }
                }
              }
            }
          }
          
        }
      }
    }
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
          } else {
            print(line)
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
