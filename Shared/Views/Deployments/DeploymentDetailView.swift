//
//  DeploymentDetailView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import SwiftUI

struct DeploymentDetailView: View {
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID { session.account.id }
	var deploymentId: VercelDeployment.ID
	@State var deployment: VercelDeployment?

	var body: some View {
		Form {
			if let deployment {
				Overview(deployment: deployment)
				Section("Deployment Cause") {
					switch deployment.deploymentCause {
					case let .deployHook(name):
						Text("\(Image(deployment.deploymentCause.icon!)) \(name)", comment: "Deploy hook cause icon and name")
					case .promotion(_):
						Text("\(Image(systemName: "arrow.up.circle")) \(deployment.deploymentCause.description)", comment: "Promoted deployment cause icon and name")
						if let commit = deployment.commit {
							CommitSummary(commit: commit)
						}
					case .manual:
						Text("Manual Deployment", comment: "Manual deployment cause label")
					case let .gitCommit(commit):
						CommitSummary(commit: commit)
					}
				}
				URLDetails(accountId: accountId, deployment: deployment)
				DeploymentDetails(accountId: accountId, deployment: deployment)
			} else {
				ProgressView()
			}
		}
		.navigationTitle("Deployment Details")
		.makeContainer()
		.dataTask {
			do {
				try await loadDeploymentDetails()
			} catch {
				print(error)
			}
		}
	}

	private func loadDeploymentDetails() async throws {
		var request = VercelAPI.request(for: .deployments(deploymentID: deploymentId), with: accountId)
		try session.signRequest(&request)

		let (data, _) = try await URLSession.shared.data(for: request)
		let decoded = try JSONDecoder().decode(VercelDeployment.self, from: data)
		deployment = decoded
	}
}

private struct CommitSummary: View {
	var commit: AnyCommit
	
	var body: some View {
		Text(commit.commitMessageSummary)
		Link(destination: commit.commitUrl) {
			Text("\(Image(commit.provider.rawValue)) \(Text(commit.shortSha).font(.system(.footnote, design: .monospaced))) by \(commit.commitAuthorName) in \(commit.org)/\(commit.repo)", comment: "Commit details ({icon} {shortsha} by {authorName} in {repo})")
				.font(.footnote)
		}
		.contextMenu {
			Section {
				Button {
					Pasteboard.setString(commit.commitSha)
				} label: {
					Text("Copy Commit Sha")
				}
				
				Button {
					Pasteboard.setString(commit.commitUrl.absoluteString)
				} label: {
					Text("Copy Commit URL")
				}
			} header: {
				Label("Copy", systemImage: "doc.on.doc")
			}
		}
	}
}

private struct Overview: View {
	var deployment: VercelDeployment

	var body: some View {
		Section("Overview") {
			LabelView("Project") {
				Text(deployment.project)
			}

			LabelView("Status") {
				DeploymentStateIndicator(state: deployment.state)
			}

			LabelView("Target") {
				if deployment.target == .production {
					Label("Production", systemImage: "theatermasks")
						.symbolVariant(.fill)
				} else {
					Text("Preview")
				}
			}
		}
	}
}

private struct URLDetails: View {
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID
	var deployment: VercelDeployment

	@State private var aliases: [VercelAlias] = []

	var body: some View {
		Section(header: Text("Deployment URL")) {
			Link(destination: deployment.url) {
				Label(deployment.url.absoluteString, systemImage: "link").lineLimit(1)
			}.keyboardShortcut("o", modifiers: [.command])

			Button {
				Pasteboard.setString(deployment.url.absoluteString)
			} label: {
				Label("Copy URL", systemImage: "doc.on.doc")
			}.keyboardShortcut("c", modifiers: [.command])

			DisclosureGroup {
				if aliases.isEmpty {
					Text("No aliases assigned to deployment")
						.foregroundColor(.secondary)
				} else {
					ForEach(aliases, id: \.self) { alias in
						HStack {
							Link(destination: alias.url) {
								Text(alias.url.absoluteString).lineLimit(1)
							}
							Spacer()
						}
					}
				}
			} label: {
				Label("Deployment Aliases", systemImage: "arrowshape.turn.up.right")
					.badge(aliases.count)
			}
			.task {
				do {
					var request = VercelAPI.request(
						for: .deployments(
							version: 5,
							deploymentID: deployment.id,
							path: "aliases"
						),
						with: accountId
					)
					try session.signRequest(&request)
					let (data, _) = try await URLSession.shared.data(for: request)
					try withAnimation {
						aliases = try JSONDecoder().decode(VercelAlias.APIResponse.self, from: data).aliases
					}
				} catch {
					print(error)
				}
			}
		}
	}
}

private struct DeploymentDetails: View {
	@Environment(\.dismiss) var dismiss
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID
	var deployment: VercelDeployment

	@State var cancelConfirmation = false
	@State var deleteConfirmation = false
	@State var redeployConfirmation = false
	@State var promoteToProductionConfirmation = false
	@State var instantRollbackConfirmation = false

	@State var mutating = false
	@State var recentlyCancelled = false

	var body: some View {
		Section("Details") {
			NavigationLink {
				DeploymentLogView(deployment: deployment, accountID: accountId)
					.environmentObject(session)
			} label: {
				Label("View Logs", systemImage: "terminal")
			}
			
			Group {
				if let promoteToProductionDataPayload = deployment.promoteToProductionDataPayload {
					Button {
						promoteToProductionConfirmation = true
					} label: {
						Label("Promote to Production", systemImage: "arrow.up.circle")
					}
					.confirmationDialog("Promote to Production", isPresented: $promoteToProductionConfirmation) {
						Button(role: .cancel) {
							promoteToProductionConfirmation = false
						} label: {
							Text("Cancel")
						}
						
						Button {
							Task { await promoteToProduction(data: promoteToProductionDataPayload) }
						} label: {
							Text("Promote to Production")
						}
					} message: {
						VStack {
							Text("This Deployment will be promoted to Production. This Project's domains will point to your new deployment, and all Environment Variables defined for the Production Environment in the Project Settings will be applied.")
						}
					}
				}
				
				if let redeployPayload = deployment.redeployDataPayload {
					Button {
						redeployConfirmation = true
					} label: {
						Label("Redeploy", systemImage: "arrow.clockwise")
					}
					.confirmationDialog("Redeploy\(deployment.target == .production ? " to Production" : "")", isPresented: $redeployConfirmation) {
						Button(role: .cancel) {
							redeployConfirmation = false
						} label: {
							Text("Cancel")
						}
						
						Button {
							Task { await redeploy(data: redeployPayload) }
						} label: {
							Text("Redeploy")
						}
						
						Button {
							Task { await redeploy(withCache: true, data: redeployPayload) }
						} label: {
							Text("Redeploy with existing Build Cache")
						}
					} message: {
						Text("You are about to create a new Deployment with the same source code as your current Deployment, but with the newest configuration from your Project Settings.")
					}
				}
				
				if (deployment.state != .queued && deployment.state != .building)
						|| deployment.state == .cancelled
						|| recentlyCancelled
				{
					Button(role: .destructive, action: { deleteConfirmation = true }) {
						HStack {
							Label("Delete Deployment", systemImage: "trash")
						}
					}
					.alert(isPresented: $deleteConfirmation) {
						Alert(
							title: Text("Are you sure you want to delete this deployment?"),
							message: Text("Deleting this deployment might break links used in integrations, such as the ones in the pull requests of your Git provider. This action cannot be undone."),
							primaryButton: .destructive(Text("Delete", comment: "Confirmation label for deleting a deployment"), action: {
								Task { await deleteDeployment() }
							}),
							secondaryButton: .cancel()
						)
					}
					.symbolRenderingMode(.multicolor)
				} else {
					Button(role: .destructive, action: { cancelConfirmation = true }) {
						HStack {
							Label("Cancel Deployment", systemImage: "xmark")
							
							if mutating {
								Spacer()
								ProgressView()
							}
						}
					}
					.alert(isPresented: $cancelConfirmation) {
						Alert(
							title: Text("Are you sure you want to cancel this deployment?"),
							message: Text("This will immediately stop the build, with no option to resume."),
							primaryButton: .destructive(Text("Cancel Deployment"), action: {
								Task { await cancelDeployment() }
							}),
							secondaryButton: .cancel(Text("Close", comment: "Label to dismiss the build cancellation confirmation"))
						)
					}
					.symbolRenderingMode(.multicolor)
				}
			}
			.disabled(mutating)
		}
	}
	
	func promoteToProduction(data: Data) async {
		mutating = true
		
		do {
			var request = VercelAPI.request(for: .deployments(version: 13), with: accountId, method: .POST)
			request.httpBody = data
			try session.signRequest(&request)
			
			let _ = try await URLSession.shared.data(for: request)
			dismiss()
		} catch {
			print(error)
		}
		
		mutating = false
	}
	
	func redeploy(withCache: Bool = false, data: Data) async {
		mutating = true
		
		do {
			var queryItems = [URLQueryItem(name: "forceBuild", value: "1")]
			
			if withCache {
				queryItems.append(URLQueryItem(name: "withCache", value: "1"))
			}
			
			var request = VercelAPI.request(for: .deployments(version: 13), with: accountId, queryItems: queryItems, method: .POST)
			request.httpBody = data
			try session.signRequest(&request)
			
			let _ = try await URLSession.shared.data(for: request)
			dismiss()
		} catch {
			print(error)
		}
		
		mutating = false
	}

	func deleteDeployment() async {
		mutating = true

		do {
			var request = VercelAPI.request(
				for: .deployments(version: 13, deploymentID: deployment.id),
				with: accountId,
				method: .DELETE
			)
			try session.signRequest(&request)

			let (_, response) = try await URLSession.shared.data(for: request)

			if let response = response as? HTTPURLResponse,
			   response.statusCode == 200
			{
				#if !os(macOS)
					dismiss()
				#endif
			}
		} catch {
			print("Error deleting deployment: \(error.localizedDescription)")
		}

		mutating = false
	}

	func cancelDeployment() async {
		mutating = true

		do {
			var request = VercelAPI.request(
				for: .deployments(version: 12, deploymentID: deployment.id, path: "cancel"),
				with: accountId,
				method: .PATCH
			)
			try session.signRequest(&request)

			let (_, response) = try await URLSession.shared.data(for: request)

			if let response = response as? HTTPURLResponse,
			   response.statusCode == 200
			{
				recentlyCancelled = true
			}
		} catch {
			print("Error cancelling deployment: \(error.localizedDescription)")
		}

		mutating = false
	}
}
