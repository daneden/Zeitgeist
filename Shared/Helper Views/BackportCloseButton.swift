//
//  BackportCloseButton.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 26/08/2025.
//

import SwiftUI

struct BackportCloseButton: View {
	let action: () -> Void
	
	var body: some View {
		if #available(iOS 26, macOS 26, visionOS 26, watchOS 26, *) {
			Button(role: .close) {
				action()
			}
		} else {
			Button("Close", systemImage: "xmark") {
				action()
			}
		}
	}
}

#Preview {
	BackportCloseButton {
		
	}
}
