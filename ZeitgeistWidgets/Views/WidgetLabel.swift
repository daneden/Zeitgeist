//
//  ZeitgeistWidgets.swift
//  ZeitgeistWidgets
//
//  Created by Daniel Eden on 31/05/2021.
//

import SwiftUI

struct WidgetLabel: View {
	var label: String
	var iconName: String

	var body: some View {
		Text("\(Image(systemName: iconName)) \(label)", comment: "A widget label with an icon and label text")
			.fontWeight(.medium)
			.padding(2)
			.padding(.horizontal, 2)
			.background(.thickMaterial)
			.clipShape(ContainerRelativeShape())
	}
}
