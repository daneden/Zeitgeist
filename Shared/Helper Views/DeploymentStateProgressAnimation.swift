//
//  DeploymentStateProgressAnimation.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/01/2026.
//
import SwiftUI

struct DeploymentStateProgressAnimation: View {
	var state: VercelDeployment.State
	@State var phase: CGFloat = 0
	@State var isHidden = true
	
	var glowAlignment: UnitPoint {
		switch state {
		case .building, .queued:
			// Move along the top edge from left (x ~ 0.05) to right (x ~ 0.95)
			UnitPoint(x: 0.05 + 0.90 * phase, y: 0)
		default:
				.top
		}
	}
	
	var animationDuration: TimeInterval {
		switch state {
		case .building: 1
		case .queued: 3
		default: 5
		}
	}

	var singleCycleAnimation: Animation {
		switch state {
		case .building:
			.timingCurve(0.8, 0.16, 0.4, 1, duration: animationDuration)
		case .queued:
			.easeInOut(duration: animationDuration)
		default:
			.default
		}
	}

	var body: some View {
		GeometryReader { geometry in
			HStack {
				EllipticalGradient(
					colors: [state.color.opacity(0.3), .clear],
					center: glowAlignment,
					startRadiusFraction: 0,
					endRadiusFraction: isHidden ? 0 : width(in: geometry.size) / geometry.size.width
				)
				.opacity(isHidden ? 0 : 1)
			}
		}
		.animation(.default, value: state)
		.task(id: state) {
			switch state {
			case .building, .queued:
				// Only reset phase when coming from a non-animating state
				if isHidden {
					phase = 0
					withAnimation(.easeOut(duration: 0.3)) {
						isHidden = false
					}
					try? await Task.sleep(for: .milliseconds(150))
				}

				// Continuously animate back and forth, allowing smooth timing transitions
				while !Task.isCancelled {
					let targetPhase: CGFloat = phase < 0.5 ? 1 : 0
					withAnimation(singleCycleAnimation) {
						phase = targetPhase
					}
					try? await Task.sleep(for: .seconds(animationDuration))
				}
			default:
				// Stop the motion by settling the phase in the middle
				withAnimation(.smooth) {
					phase = 0.5
				}
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
		case .building, .queued: size.width / 2
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
