//
//  Tooltip.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

public extension View {
    /// Overlays this view with a view that provides a Help Tag.
    func toolTip(_ toolTip: String) -> some View {
        self.overlay(TooltipView(toolTip: toolTip))
    }
}

private struct TooltipView: NSViewRepresentable {
    let toolTip: String

    func makeNSView(context: NSViewRepresentableContext<TooltipView>) -> NSView {
        NSView()
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<TooltipView>) {
        nsView.toolTip = self.toolTip
    }
}
