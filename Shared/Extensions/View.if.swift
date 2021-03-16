//
//  View.if.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

extension View {
  func `if`<Content: View>(_ condition: Bool, content: (Self) -> Content) -> some View {
       if condition {
           return AnyView(content(self))
       } else {
           return AnyView(self)
       }
   }
}
