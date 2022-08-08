//
//  OnboardingView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct OnboardingView: View {
	@State var signInModel = SignInViewModel()

	var body: some View {
		GeometryReader { geometry in
			ScrollView {
				VStack(spacing: 12) {
					Spacer()

					Image("appIcon")

					Text("Welcome to Zeitgeist")
						.font(.largeTitle.bold())
					Text("Zeitgeist lets you see and manage your Vercel deployments.")
					Text("Watch builds complete, cancel or delete them, and get quick access to their URLs, logs, and commits.")
						.padding(.bottom)

					Button(action: { signInModel.signIn() }) {
						HStack {
							Spacer()
							Label("Sign In With Vercel", systemImage: "triangle.fill")
							Spacer()
						}
						.font(.body.bold())
						.padding()
						.padding(.horizontal)
					}.buttonStyle(.borderedProminent)

					Text("To get started, sign in with your Vercel account.")
						.font(.caption)
						.foregroundColor(.secondary)

					Spacer()
				}
				.padding()
				.frame(minHeight: geometry.size.height)
			}
			.background(LinearGradient(gradient: Gradient(colors: [.accentColor.opacity(0.2), .accentColor.opacity(0)]), startPoint: .top, endPoint: .center))
		}
	}
}

struct OnboardingView_Previews: PreviewProvider {
	static var previews: some View {
		OnboardingView()
	}
}
