//
//  NewFeaturesView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 21/08/2022.
//

import SwiftUI

enum IconType {
	case system, custom
}

struct FeatureDescription: Hashable, Identifiable {
	var id: Int { hashValue }
	var heading: String
	var description: String
	var iconName: String
	var iconType: IconType = .system
}

struct NewFeaturesView: View {
	@ScaledMetric var width: CGFloat = 50
	@Environment(\.presentationMode) private var presentationMode
	let features: [FeatureDescription] = [
		FeatureDescription(heading: "Projects View",
											 description: "Browse by projects, and quickly see their Git connections and latest deployments.",
											 iconName: "folder"),
		FeatureDescription(heading: "Redeploy",
											 description: "Redeploy instantly from a deployment's detail view, with or without the existing build cache.",
											 iconName: "arrow.clockwise"),
		FeatureDescription(heading: "Notification Improvements ",
											 description: "Manage notifications on a per-project basis, and optionally only get notifications for production deployments.",
											 iconName: "bell.badge"),
		FeatureDescription(heading: "Deploy Hooks",
											 description: "Added support for deploy hooks means at-a-glance clarity on the cause of a deployment.",
											 iconName: "hook",
											 iconType: .custom)
	]
	
	var body: some View {
		GeometryReader { geometry in
			ScrollView {
				VStack(spacing: 24) {
					Spacer()
					Text("What’s new in Zeitgeist")
						.font(.largeTitle.bold())
						.multilineTextAlignment(.center)
					Spacer()
					VStack(alignment: .leading, spacing: 24) {
						ForEach(features) { feature in
							HStack {
								Group {
									switch feature.iconType {
									case .system:
										Image(systemName: feature.iconName)
									case .custom:
										Image(feature.iconName)
									}
								}
								.font(.largeTitle.weight(.light))
								.foregroundStyle(.tint)
								.frame(width: width)
								
								VStack(alignment: .leading) {
									Text(feature.heading).font(.headline)
									Text(feature.description).foregroundStyle(.secondary)
								}
							}
						}
					}
					
					Spacer()
					Spacer()
					
					Button {
						presentationMode.wrappedValue.dismiss()
					} label: {
						HStack {
							Spacer()
							Text("Continue").fontWeight(.semibold)
							Spacer()
						}
						.padding()
					}.buttonStyle(.borderedProminent)
				}
				.padding()
				.frame(minHeight: geometry.size.height)
			}
		}
	}
}

struct NewFeaturesView_Previews: PreviewProvider {
	static var previews: some View {
		NewFeaturesView()
	}
}
