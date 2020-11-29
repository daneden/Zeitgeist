//
//  ZeitgeistLogo.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct ZeitgeistLogo: View {
  let imageWidth = CGFloat(80.0)
  
  var body: some View {
    VStack(alignment: .center, spacing: 8) {
      
      Image("appIcon")
        .resizable()
        .scaledToFit()
        .frame(width: imageWidth, height: imageWidth)
        
      Text("Zeitgeist")
        .fontWeight(.bold)
        .font(.title)
      Text("Zeitgeist helps you stay on top of your Vercel deployments. See deployments wait, build, and finish (or fail), and quickly access their URLs, logs, or commits.")
      
    }
    .padding(.vertical)
  }
}

struct ZeitgeistLogo_Previews: PreviewProvider {
    static var previews: some View {
        ZeitgeistLogo()
    }
}
