//
//  LatestEventMenuBarLabel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/06/2023.
//

import SwiftUI

struct LatestEventMenuBarLabel: View {
	@State private var latestEvent: VercelDeployment.State?
	@State private var lastReceivedEvent = Date.now
	
	let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
	
	var body: some View {
		Label("Zeitgeist", systemImage: latestEvent?.imageName ?? VercelDeployment.State.normal.imageName)
			.symbolVariant(.fill)
			.symbolRenderingMode(.hierarchical)
			.onReceive(NotificationCenter.default.publisher(for: .ZPSNotification)) { notificationPayload in
				guard let userInfo = notificationPayload.userInfo,
							let eventTypeString = userInfo["eventType"] as? String,
							let eventType: ZPSEventType = ZPSEventType(rawValue: eventTypeString) else {
					return
				}
				
				withAnimation {
					latestEvent = eventType.associatedState
					lastReceivedEvent = .now
				}
			}
			.onReceive(timer) { _ in
				if latestEvent != nil && abs(lastReceivedEvent.distance(to: .now)) > 60 {
					latestEvent = nil
				}
			}
	}
}

struct LatestEventMenuBarLabel_Previews: PreviewProvider {
    static var previews: some View {
        LatestEventMenuBarLabel()
    }
}
