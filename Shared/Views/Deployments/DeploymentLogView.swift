//
//  DeploymentLogView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 09/01/2022.
//

import SwiftUI
import Suite

fileprivate struct LogEntryMaxWidthPreferenceKey: PreferenceKey {
	static var defaultValue: CGFloat = 0
	
	static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
		value = max(value, nextValue())
	}
}

struct LogEvent: Codable, Identifiable {
	enum EventType: String, Codable {
		case command, stderr, stdout, delimiter, exit
	}
	
	struct DeploymentStateInfo: Codable {
		var name: String
		var readyState: VercelDeployment.State
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
	enum DisplayOption {
		case timestamp, log, both
	}
	
	@State private var logLineSize: CGSize = .zero
	
	var event: LogEvent
	var display: DisplayOption = .both
	
	var body: some View {
		HStack(alignment: .firstTextBaseline) {
			if display == .timestamp || display == .both {
				Text(event.date, style: .time)
					.foregroundStyle(.secondary)
					.fixedSize(horizontal: true, vertical: false)
			}
			
			if display == .log || display == .both {
				Text(event.text)
					.foregroundStyle(.primary)
					.fixedSize(horizontal: true, vertical: false)
					.frame(maxWidth: .infinity, alignment: .leading)
			}
		}
		.scenePadding(.horizontal)
		.padding(.vertical, 2)
		.readSize($logLineSize)
		.preference(key: LogEntryMaxWidthPreferenceKey.self, value: logLineSize.width)
		.background {
			if event.type == .stderr {
				Color.clear
					.background(.quinary)
			}
		}
		.foregroundStyle(event.outputColor)
	}
}

struct DeploymentLogView: View {
	@EnvironmentObject private var session: VercelSession
	
	@State private var followLogs = false
	@State private var logEvents: [LogEvent] = []
	@State private var maxLineWidth: CGFloat = 0
	
	var deployment: VercelDeployment
	
	var accountID: VercelAccount.ID {
		session.account.id
	}
	
	var body: some View {
		ScrollViewReader { proxy in
			GeometryReader { geometry in
				ScrollView([.horizontal, .vertical]) {
					LazyVStack(alignment: .leading, spacing: 0) {
						ForEach(logEvents) { event in
							LogEventView(event: event)
								.id(event.id)
						}
					}
					.frame(minWidth: maxLineWidth, alignment: .leading)
					.textSelection(.enabled)
					.font(.footnote.monospaced())
					.onPreferenceChange(LogEntryMaxWidthPreferenceKey.self) { width in
						maxLineWidth = width
					}
				}
				.modify {
					if #available(iOS 17, macOS 14, *) {
						$0.defaultScrollAnchor(followLogs ? .bottom : .top)
					} else {
						$0
							.task(id: logEvents.last?.id) {
								if followLogs, let latestEvent = logEvents.last {
									proxy.scrollTo(latestEvent.id, anchor: .bottomLeading)
								}
							}
					}
				}
				.toolbar {
					ToolbarItemGroup {
						Toggle(isOn: $followLogs) {
							Label("Follow logs", systemImage: "arrow.down.to.line.compact")
								.padding(-4)
								.padding(.horizontal, -4)
						}
						.toggleStyle(.button)
						.disabled(logEvents.isEmpty)
						.onChange(of: followLogs) { _ in
							if followLogs {
								proxy.scrollTo(logEvents.last?.id, anchor: .bottomLeading)
							}
						}
						
						Link(destination: deployment.inspectorUrl) {
							Label("Open in Safari", systemImage: "safari")
						}
					}
				}
			}
		}
		.overlay {
			if logEvents.isEmpty {
				ProgressView()
			}
		}
		.navigationTitle(Text("Build Logs"))
		.task {
			do {
				let queryItems: [URLQueryItem] = [
					URLQueryItem(name: "follow", value: "1"),
					URLQueryItem(name: "limit", value: "-1"),
				]
				
				var request = VercelAPI.request(
					for: .deployments(version: 2, deploymentID: deployment.id, path: "events"),
					with: accountID,
					queryItems: queryItems
				)
				try session.signRequest(&request)
				
				let (data, _) = try await URLSession.shared.bytes(for: request)
				
				for try await line in data.lines {
					if let lineAsData = line.data(using: .utf8),
						 let event = try? JSONDecoder().decode(LogEvent.self, from: lineAsData)
					{
						logEvents.append(event)
					}
				}
			} catch {
				print(error.localizedDescription)
			}
		}
	}
}
