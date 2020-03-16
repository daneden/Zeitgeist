//
//  ProgressIndicator.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 14/03/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct ProgressIndicator: NSViewRepresentable {
  func makeNSView(context: NSViewRepresentableContext<ProgressIndicator>) -> NSProgressIndicator {
    let result = NSProgressIndicator()
    result.isIndeterminate = true
    result.startAnimation(nil)

    result.controlSize = .small
    result.style = .spinning

    return result
  }

  func updateNSView(_ nsView: NSProgressIndicator, context: NSViewRepresentableContext<ProgressIndicator>) {

  }
}

struct ProgressIndicator_Previews: PreviewProvider {
    static var previews: some View {
        ProgressIndicator()
    }
}
