//
//  ZeitgeistLogo.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct ZeitgeistLogo: View {
  let imageWidth = CGFloat(48.0)
  let radius = CGFloat(8.0)
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      #if os(macOS)
      Spacer()
      #endif
      
      Image("appIcon")
        .resizable()
        .scaledToFit()
        .frame(width: imageWidth, height: imageWidth)
        .cornerRadius(radius)
        .overlay(
          RoundedRectangle(cornerRadius: radius)
            .stroke(Color.primary.opacity(0.35), lineWidth: 1)
            
        )
        .blendMode(.overlay)
        .shadow(color: Color.black.opacity(0.1), radius: 12, x: 0, y: 4)
        
      Text("Zeitgeist")
        .fontWeight(.bold)
        .font(.title)
      Text("Zeitgeist helps you stay on top of your Vercel deployments. See deployments wait, build, and finish (or fail), and quickly access their URLs, logs, or commits.")
      
      #if os(macOS)
      Spacer()
      #endif
    }
    .padding(.vertical)
  }
}

struct ZeitgeistLogo_Previews: PreviewProvider {
    static var previews: some View {
        ZeitgeistLogo()
    }
}
