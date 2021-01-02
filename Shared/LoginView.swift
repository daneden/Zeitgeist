//
//  LoginView.swift
//  ZeitgeistTests
//
//  Created by Daniel Eden on 01/08/2020.
//  Copyright © 2020 Daniel Eden. All rights reserved.
//

import SwiftUI

struct LoginView: View {
  @StateObject var viewModel = SignInViewModel()
  
  #if os(macOS)
  var padding = 16.0 as CGFloat
  #else
  var padding = 0 as CGFloat
  #endif
  
  var body: some View {
    Form {
      ZeitgeistLogo()
      
      Section {
        Button(action: { viewModel.signIn() }, label: {
          Label("Sign in with Vercel", systemImage: "triangle.fill")
        })
      }
    }
    .padding(.all, padding)
  }
}
