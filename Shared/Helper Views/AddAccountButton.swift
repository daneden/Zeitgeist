//
//  AddAccountButton.swift
//  Verdant
//
//  Created by Daniel Eden on 29/05/2021.
//

import SwiftUI

struct AddAccountButton: View {
	var label = "Sign In With Vercel"
	var iconName = "triangle.fill"

	@State var signInViewModel = SignInViewModel()

	var body: some View {
		Button(action: { self.signInViewModel.signIn() }) {
			Label(label, systemImage: iconName)
		}
	}
}

struct AddAccountButton_Previews: PreviewProvider {
	static var previews: some View {
		AddAccountButton()
	}
}
