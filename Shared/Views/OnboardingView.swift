//
//  OnboardingView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct ZeitgeistLogo: View {
	@ScaledMetric var size = 128
	@State private var appear = false
	
	var body: some View {
		ZStack {
			AngularGradient(colors: [
				Color(red: 0.34, green: 0, blue: 0.78),
				Color(red: 0.11, green: 0.37, blue: 0.92),
				Color(red: 0, green: 0.56, blue: 0.97),
				Color(red: 0, green: 0.61, blue: 0.95),
				Color(red: 0, green: 0.4, blue: 0.91),
				Color(red: 0.39, green: 0.33, blue: 0.89),
				Color(red: 0.76, green: 0.31, blue: 0.86),
				Color(red: 1, green: 0.33, blue: 0.71),
				Color(red: 1, green: 0.39, blue: 0.43),
				Color(red: 1, green: 0.54, blue: 0.19),
				Color(red: 1, green: 0.38, blue: 0.44),
				Color(red: 0.87, green: 0.25, blue: 0.81),
				Color(red: 0.34, green: 0, blue: 0.78),
			], center: .center, angle: Angle(degrees: appear ? 360 : 0))
			.scaleEffect(2)
			.blur(radius: size * 0.1)
			.clipShape(RoundedRectangle(cornerRadius: size * 0.25, style: .continuous))
			.overlay {
				RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
					.strokeBorder(Color.primary.opacity(0.1), style: .init())
			}
			.animation(.linear(duration: 30).repeatForever(autoreverses: false), value: appear)
			.onAppear {
				appear = true
			}
			Image(systemName: "triangle.fill")
				.resizable()
				.scaledToFit()
				.padding()
				.padding()
				.foregroundColor(.white)
				.shadow(color: .black.opacity(0.3), radius: size * 0.2, x: 0, y: size * 0.1)
		}
		.frame(width: size, height: size)
		.shadow(color: .black.opacity(0.1), radius: size * 0.2, x: 0, y: size * 0.1)
	}
}

struct OnboardingView: View {
	@State var signInModel = SignInViewModel()
	
	var body: some View {
		GeometryReader { geometry in
			ScrollView {
				VStack(spacing: 12) {
					Spacer()

					ZeitgeistLogo()
						.padding(.vertical)
					
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
					
					HStack {
						Link(destination: URL(string: "https://zeitgeist.daneden.me/privacy")!) {
							HStack {
								Spacer()
								Text("Privacy Policy")
								Spacer()
							}
						}
						
						Link(destination: URL(string: "https://zeitgeist.daneden.me/terms")!) {
							HStack {
								Spacer()
								Text("Terms of Use")
								Spacer()
							}
						}
					}
					.buttonStyle(.bordered)
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
