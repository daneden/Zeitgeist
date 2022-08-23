//
//  NotificationPreviews.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 23/08/2022.
//

import SwiftUI

struct NotificationPreviews: View {
	var eventType: ZPSEventType = .deployment
	var projectName = "my-project"
	var description = "Caused by alexanger's commit \"Initial commit\""
	var showsEmoji = false
	
	private var title: String {
		switch eventType {
		case .deployment:
			return "\(emoji)New build started for \(projectName)"
		case .deploymentReady:
			return "\(emoji)Deployment ready for \(projectName)"
		case .deploymentError:
			return "\(emoji)Build failed for \(projectName)"
		case .projectCreated:
			return "\(emoji)Project Created"
		case .projectRemoved:
			return "\(emoji)Project Removed"
		}
	}
	
	private var emoji: String {
		guard showsEmoji else { return "" }
		
		return eventType.emojiPrefix
	}
	
    var body: some View {
			HStack {
				Image("StaticAppIcon")
					.resizable()
					.frame(width: 40, height: 40)
					.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
					.padding(.trailing, 8)
				
				VStack(alignment: .leading) {
					Text(title)
						.font(.headline)
					Text(description)
				}
				
				Spacer(minLength: 0)
			}
			.padding()
			.background(.thinMaterial)
			.clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct NotificationPreviews_Previews: PreviewProvider {
    static var previews: some View {
			Group {
				NotificationPreviews()
				NotificationPreviews(eventType: .deploymentError)
				
				NotificationPreviews(showsEmoji: true)
				NotificationPreviews(eventType: .deploymentError, showsEmoji: true)
			}
			.padding()
			.previewLayout(.sizeThatFits)
    }
}
