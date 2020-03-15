//
//  BlurView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 15/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI
import Foundation
import Cocoa

struct BlurView: NSViewRepresentable {
  typealias NSViewType = NSVisualEffectView
  
  public func makeNSView(context: NSViewRepresentableContext<BlurView>) -> NSVisualEffectView {
    let view = NSVisualEffectView()
    view.blendingMode = .behindWindow
    view.material = .toolTip
    return view
  }
  
  public func updateNSView(_ nsView: NSVisualEffectView, context: NSViewRepresentableContext<BlurView>) {
    
  }
}

struct BlurView_Previews: PreviewProvider {
    static var previews: some View {
        BlurView()
    }
}
