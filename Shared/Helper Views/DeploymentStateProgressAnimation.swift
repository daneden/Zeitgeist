//
//  DeploymentStateProgressAnimation.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/01/2026.
//
import SwiftUI

struct DeploymentStateProgressAnimation: View {
	var state: VercelDeployment.State
	@State var isAnimating = false
	@State var isHidden = true
	
	var glowAlignment: Alignment {
		switch state {
		case .building, .queued: isAnimating ? .trailing : .leading
		default: .center
		}
	}
	
	var animationDuration: TimeInterval {
		switch state {
		case .building: 1
		case .queued: 3
		default: 5
		}
	}
	
	var animation: Animation {
		switch state {
		case .building: .timingCurve(0.8, 0.16, 0.4, 1, duration: animationDuration).repeatForever()
		case .queued: .easeInOut(duration: animationDuration)
				.repeatForever()
		default: .default
		}
	}
	
	var body: some View {
		GeometryReader { geometry in
			HStack {
					Ellipse()
						.fill(state.color.gradient.tertiary)
						.frame(maxWidth: width(in: geometry.size), maxHeight: 40)
						.blur(radius: 20)
						.opacity(isHidden ? 0 : 1)
						.scaleEffect(isHidden ? 0.5 : 1, anchor: .top)
						.offset(x: 0, y: geometry.size.height / -2)
						
			}
			.frame(maxWidth: .infinity, alignment: glowAlignment)
			.animation(animation, value: isAnimating)
			.padding(.horizontal)
			.position(x: geometry.size.width / 2, y: 0)
			.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
		}
		.animation(.default, value: state)
		.task(id: state) {
			isAnimating = false
			
			switch state {
			case .building, .queued:
				isAnimating = true
				withAnimation { isHidden = false }
			default:
				isAnimating = false

				if !isHidden {
					withAnimation(.smooth(duration: 2).delay(2)) {
						isHidden = true
					}
				}
			}
		}
	}
	
	func width(in size: CGSize) -> CGFloat {
		switch state {
		case .building, .queued: size.width / 3
		default: size.width / 1.25
		}
	}
}

#Preview {
	@Previewable @State var previewState = VercelDeployment.State.building
	
	VStack {
		Text(previewState.description)
			.frame(maxWidth: .infinity, alignment: .leading)
	}
	.padding()
	.overlay {
		DeploymentStateProgressAnimation(state: previewState)
	}
	
	ForEach(VercelDeployment.State.allCases, id: \.self) { state in
		Button(state.description) {
			previewState = state
		}
	}
}
