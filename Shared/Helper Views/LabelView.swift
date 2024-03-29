//
//  DeploymentDetailLabel.swift
//  Verdant
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

fileprivate struct ValueLabelStyle: LabelStyle {
	func makeBody(configuration: Configuration) -> some View {
		HStack {
			configuration.icon
			configuration.title
		}
	}
}

struct LabelView<S: View, Content: View>: View {
	var label: S
	var content: Content

	init(_ label: @escaping () -> S, @ViewBuilder content: () -> Content) {
		self.label = label()
		self.content = content()
	}

	var body: some View {
		if #available(iOS 16.0, macOS 13.0, *) {
			LabeledContent {
				content
					.labelStyle(ValueLabelStyle())
			} label: {
				label
					.alignmentGuide(.listRowSeparatorLeading, computeValue: { dimension in
						dimension[.listRowSeparatorLeading]
					})
			}

		} else {
			HStack {
				label
				Spacer()
				content
					.foregroundStyle(.secondary)
			}
		}
	}
}

extension LabelView where S == Text {
	init(_ label: LocalizedStringKey, @ViewBuilder content: () -> Content) {
		self.label = Text(label)
		self.content = content()
	}
	
	init(_ label: Text, @ViewBuilder content: () -> Content) {
		self.label = label
		self.content = content()
	}
}

struct DeploymentDetailLabel_Previews: PreviewProvider {
	static var previews: some View {
		LabelView("Label") {
			Text("Value")
		}
	}
}
