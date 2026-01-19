//
//  EnvironmentVariableRowView.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 13/09/2022.
//

import SwiftUI

struct EnvironmentVariableRowView: View {
	@Environment(\.session) private var session
	var projectId: VercelProject.ID
	var envVar: VercelEnv
	
	var body: some View {
		VStack(alignment: .leading, spacing: 4) {
			HStack {
				Text(envVar.key)
					.lineLimit(2)
					.font(.footnote.monospaced())
				
				Spacer()
				
				Text(envVar.updated, style: .relative)
					.font(.caption)
					.foregroundStyle(.secondary)
			}
			
			EnvironmentVariableDecryptingView(projectId: projectId, envVar: envVar)
			
			Text(LocalizedStringKey(envVar.target.map { $0.capitalized }.formatted(.list(type: .and))), comment: "A list of target environments for an environment variable")
				.font(.caption)
				.foregroundStyle(.tertiary)
				.textSelection(.disabled)
		}
		.frame(maxWidth: .infinity, alignment: .leading)
	}
}

struct EnvironmentVariableDecryptingView: View {
	@Environment(\.session) private var session
	
	var projectId: VercelProject.ID
	
	@State var envVar: VercelEnv
	var showSpacer = true
	
	@State private var needsDecrypting = true
	@State private var decrypting = false
	
	var body: some View {
		HStack {
			Text(verbatim: needsDecrypting ? Array(repeating: "•", count: 15).joined() : envVar.value)
				.privacySensitive(!needsDecrypting)
				.contentTransition(.numericText())
				.animation(.default, value: envVar.value)
				.monospaced()
				.accessibilityHidden(needsDecrypting)
			
			if showSpacer {
				Spacer()
			}
			
			Button {
				Task {
					if envVar.decrypted != true,
						 let decrypted = await decryptedValue() {
						envVar = decrypted
					}
					
					withAnimation {
						needsDecrypting.toggle()
					}
				}
			} label: {
				Label(needsDecrypting ? "Show value" : "Hide value", systemImage: needsDecrypting ? "eye" : "eye.slash")
					.labelStyle(.iconOnly)
					.opacity(decrypting ? 0 : 1)
					.overlay {
						if decrypting {
							ProgressView()
						}
					}
			}
			.buttonStyle(.plain)
			.controlSize(.mini)
		}
	}
	
	func decryptedValue() async -> VercelEnv? {
		withAnimation { decrypting = true }
		defer {
			withAnimation { decrypting = false }
		}

		guard let session else { return nil }

		do {
			return try await EnvironmentVariableService.fetchDecrypted(
				projectId: projectId,
				envVarId: envVar.id,
				session: session
			)
		} catch {
			print(error)
			return nil
		}
	}
}

