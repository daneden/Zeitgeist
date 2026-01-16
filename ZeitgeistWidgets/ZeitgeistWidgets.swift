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
		makeBody()
	}
	
	func makeBody() -> some Widget {
		if #available(iOS 26, macOS 26, *) {
			return WidgetBundleBuilder.buildBlock(
				LatestDeploymentWidgetWithPushHandler(),
				RecentDeploymentsWidgetWithPushHandler()
			)
		} else {
			return WidgetBundleBuilder.buildBlock(
				LatestDeploymentWidget(),
				RecentDeploymentsWidget()
			)
		}
	}
}
