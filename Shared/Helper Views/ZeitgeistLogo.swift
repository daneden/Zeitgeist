//
//  ZeitgeistLogo.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 22/08/2022.
//

import SwiftUI

fileprivate let zeitgeistLogoColors = [
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
]

struct ZeitgeistLogo: View {
	@ScaledMetric var size = 128
	@State private var appear = false
	
	@ViewBuilder
	var clipShape: RoundedRectangle {
		RoundedRectangle(cornerRadius: size * 0.25, style: .continuous)
	}
	
	var body: some View {
		ZStack {
			AngularGradient(
				colors: zeitgeistLogoColors,
				center: .center
			)
			.scaleEffect(1.5)
			.blur(radius: size * 0.1)
			.rotationEffect(Angle(degrees: (appear ? 360 : 0) - 120), anchor: .center)
			.task {
				withAnimation(.linear(duration: 30).repeatForever(autoreverses: false)) {
					appear.toggle()
				}
			}
			
			Image(systemName: "triangle.fill")
				.resizable()
				.scaledToFit()
				.padding()
				.padding()
				.foregroundColor(.white)
				.shadow(color: .black.opacity(0.3), radius: size * 0.2, x: 0, y: size * 0.1)
		}
		.clipShape(clipShape)
		.overlay {
			clipShape
				.strokeBorder(Color.primary.opacity(0.2), style: .init())
				.blendMode(.plusLighter)
		}
		.frame(width: size, height: size)
		.shadow(
			color: .black.opacity(0.1),
			radius: size * 0.2,
			x: 0,
			y: size * 0.1
		)
	}
}

#Preview {
	ZeitgeistLogo()
}
