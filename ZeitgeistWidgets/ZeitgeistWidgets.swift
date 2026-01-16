//
//  ZeitgeistWidgets.swift
//  ZeitgeistWidgets
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI
import WidgetKit

@main
struct ZeitgeistWidgets: WidgetBundle {
	@WidgetBundleBuilder
	var body: some Widget {
		if #available(iOS 26, macOS 26, *) {
			LatestDeploymentWidgetWithPushHandler()
			RecentDeploymentsWidgetWithPushHandler()
		}
		
		LatestDeploymentWidget()
		RecentDeploymentsWidget()
	}
}
