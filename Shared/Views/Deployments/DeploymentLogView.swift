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

struct LogEvent: Codable, Equatable, Identifiable {
	enum EventType: String, Codable {
		case command, stderr, stdout, delimiter, exit
	}
	
	struct DeploymentStateInfo: Codable {
		var name: String
		var readyState: VercelDeployment.State
	}
	
	struct Payload: Codable, Equatable {
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
	
	var backgroundStyle: AnyShapeStyle {
		switch type {
		case .stderr: return AnyShapeStyle(.quaternary)
		default: return AnyShapeStyle(.clear)
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
	
	var previousType: LogEvent.EventType? = nil
	var nextType: LogEvent.EventType? = nil
	
	private var cornerRadii: RectangleCornerRadii {
		let matchesPrev = previousType == event.type
		let matchesNext = nextType == event.type
		switch (matchesPrev, matchesNext) {
		case (false, false):
			return .init(topLeading: 4, bottomLeading: 4, bottomTrailing: 4, topTrailing: 4)
		case (false, true):
			return .init(topLeading: 4, topTrailing: 4)
		case (true, false):
			return .init(bottomLeading: 4, bottomTrailing: 4)
		case (true, true):
			return .init()
		}
	}
	
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
		.padding(.vertical, 2)
		.padding(.horizontal, 8)
		.preference(key: LogEntryMaxWidthPreferenceKey.self, value: logLineSize.width)
		.background(event.backgroundStyle, in: UnevenRoundedRectangle(cornerRadii: cornerRadii, style: .continuous))
		.foregroundStyle(event.outputColor)
		.padding(.horizontal, -8)
		.scenePadding(.horizontal)
		.readSize($logLineSize)
		.transition(.opacity)
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
						ForEach(Array(logEvents.enumerated()), id: \.element.id) { index, event in
							let prevType = index > 0 ? logEvents[index - 1].type : nil
							let nextType = index < logEvents.count - 1 ? logEvents[index + 1].type : nil
							LogEventView(event: event, previousType: prevType, nextType: nextType)
								.id(event.id)
						}
					}
					.animation(.default, value: logEvents)
					.frame(minWidth: maxLineWidth, minHeight: geometry.size.height, alignment: .topLeading)
					.textSelection(.enabled)
					.font(.footnote.monospaced())
					.onPreferenceChange(LogEntryMaxWidthPreferenceKey.self) { width in
						maxLineWidth = width
					}
				}
				.modify {
					if #available(iOS 17, macOS 14, *) {
						$0.defaultScrollAnchor(followLogs ? .bottomLeading : .topLeading)
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
					ToolbarItem {
						Toggle(isOn: $followLogs.animation()) {
							Label("Follow logs", systemImage: "arrow.down.to.line.compact")
								.padding(-4)
								.padding(.horizontal, -4)
						}
						.toggleStyle(.button)
						.disabled(logEvents.isEmpty)
						.onChange(of: followLogs) { _ in
							if followLogs {
								withAnimation {
									proxy.scrollTo(logEvents.last?.id, anchor: .bottomLeading)
								}
							}
						}
					}
					
					if #available(iOS 26, macOS 26, *) {
						ToolbarSpacer()
					}
					
					ToolbarItem {
						Link(destination: deployment.inspectorUrl) {
							Label("Open in browser", systemImage: "safari")
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
