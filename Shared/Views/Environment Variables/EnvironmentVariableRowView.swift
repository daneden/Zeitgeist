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
	@State var envVar: VercelEnv
	@State private var loading = false
	@State private var confirmDeletion = false
	@State private var editing = false
	
	var needsDecrypting: Bool {
		envVar.decrypted == false && envVar.type == .encrypted
	}
	
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
			
			HStack(spacing: 4) {
				if envVar.type == .secret {
					Image(systemName: "lock")
				}
				
				Text(verbatim: needsDecrypting ? Array(repeating: "•", count: 15).joined() : envVar.value)
					.privacySensitive(!needsDecrypting)
					.contentTransition(.numericText())
					.animation(.default, value: envVar.value)
				
				if loading {
					ProgressView()
						.controlSize(.mini)
				}
			}
			.font(.footnote.monospaced())
			.foregroundStyle(.secondary)
			
			Text(LocalizedStringKey(envVar.target.map { $0.capitalized }.formatted(.list(type: .and))), comment: "A list of target environments for an environment variable")
				.font(.caption)
				.foregroundStyle(.tertiary)
				.textSelection(.disabled)
		}
		.sheet(isPresented: $editing) {
			NavigationStack {
				EnvironmentVariableEditView(projectId: projectId,
																		id: envVar.id,
																		key: envVar.key,
																		value: envVar.value,
																		targetProduction: envVar.targetsProduction,
																		targetPreview: envVar.targetsPreview,
																		targetDevelopment: envVar.targetsDevelopment)
			}
		}
		.onTapGesture {
			if needsDecrypting {
				Task {
					loading = true
					if let newValue = await decryptedValue() {
						envVar = newValue
					}
					loading = false
				}
			}
		}
		.textSelection(.enabled)
		.contextMenu {
			Button {
				Task {
					if needsDecrypting == false {
						Pasteboard.setString("\(envVar.key)=\(envVar.value)")
					} else {
						loading = true
						
						if let newValue = await decryptedValue() {
							Pasteboard.setString("\(newValue.key)=\(newValue.value)")
						}
						loading = false
					}
				}
			} label: {
				Label {
					HStack {
						Text("Copy")
						
						if loading {
							Spacer()
							ProgressView()
						}
					}
				} icon: {
					Image(systemName: "doc.on.doc")
				}
			}
			
			Button {
				if needsDecrypting == false {
					editing = true
				} else {
					Task {
						if let newValue = await decryptedValue() {
							envVar = newValue
							editing = true
						}
					}
				}
			} label: {
				Label("Edit", systemImage: "pencil")
			}
			
			Button(role: .destructive) {
				confirmDeletion = true
			} label: {
				Label("Delete", systemImage: "trash")
			}
		}
		.confirmationDialog("Delete environment variable", isPresented: $confirmDeletion) {
			Button(role: .cancel) {
				confirmDeletion = false
			} label: {
				Text("Cancel")
			}
			
			Button(role: .destructive) {
				Task {
					await delete()
					DataTaskModifier.postNotification()
				}
			} label: {
				Text("Delete")
			}
		} message: {
			Text("Are you sure you want to permanently delete this environment variable?")
		}
	}
	
	func decryptedValue() async -> VercelEnv? {
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

	func delete() async {
		guard let session else { return }
		do {
			try await EnvironmentVariableService.delete(
				projectId: projectId,
				envVarId: envVar.id,
				session: session
			)
		} catch {
			print(error)
		}
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

