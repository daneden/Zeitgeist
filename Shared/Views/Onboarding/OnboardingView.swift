//
//  OnboardingView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import SwiftUI

struct OnboardingView: View {
	@State var signInModel = SignInViewModel()
	@Environment(\.webAuthenticationSession) private var webAuthenticationSession
	
	var body: some View {
		GeometryReader { geometry in
			ScrollView {
				VStack(spacing: 12) {
					Spacer()

					ZeitgeistLogo()
						.padding(.vertical)
						.frame(maxWidth: .infinity)
					
					Text("Welcome to Zeitgeist")
						.font(.largeTitle)
						.fontWeight(.bold)
					
					Text("Zeitgeist lets you see and manage your Vercel deployments.")
					Text("Watch builds complete, cancel or delete them, and get quick access to their URLs, logs, and commits.")
						.padding(.bottom)
					
					Button {
						Task {
							do {
								try await signInModel.signIn(using: webAuthenticationSession)
							} catch {
								print(error.localizedDescription)
							}
						}
					} label: {
						Label {
							Text("Sign in with Vercel")
						} icon: {
							if signInModel.isSigningIn {
								ProgressView()
									.controlSize(.small)
							} else {
								Image(systemName: "triangle.fill")
							}
						}
						.frame(maxWidth: .infinity)
						.font(.headline)
					}
					.buttonStyle(.borderedProminent)
					.controlSize(.large)
					.frame(maxWidth: 400)
					.disabled(signInModel.isSigningIn)
					
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
					.frame(maxWidth: 500)
				}
				.padding()
				.frame(minHeight: geometry.size.height)
				.multilineTextAlignment(.center)
			}
			.background {
				ZStack(alignment: .top) {
					Color.clear.background(.regularMaterial).mask {
						LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
					}
					
					StatusBannerView()
						.redacted(reason: .placeholder)
				}
				.ignoresSafeArea()
			}
		}
	}
}

struct OnboardingView_Previews: PreviewProvider {
	static var previews: some View {
		OnboardingView()
	}
}
