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
	@State var deployment: VercelDeployment

	var body: some View {
		Form {
			Overview(deployment: deployment)
			URLDetails(accountId: accountId, deployment: deployment)
			DeploymentDetails(accountId: accountId, deployment: deployment)
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
		var request = VercelAPI.request(for: .deployments(deploymentID: deployment.id), with: accountId)
		try session.signRequest(&request)

		let (data, _) = try await URLSession.shared.data(for: request)
		let decoded = try JSONDecoder().decode(VercelDeployment.self, from: data)
		deployment = decoded
	}
}

private struct Overview: View {
	var deployment: VercelDeployment

	var body: some View {
		DetailSection(header: Text("Overview")) {
			LabelView("Project") {
				Text(deployment.project)
			}

			LabelView {
				Text("Deployment Cause")
			} content: {
				Group {
					switch deployment.deploymentCause {
					case let .deployHook(name):
						Text("\(Image(deployment.deploymentCause.icon!)) \(name)")
					case .manual:
						Text("Manual Deployment")
					case let .gitCommit(commit):
						Text(commit.commitMessageSummary)
						Text("\(Image(deployment.deploymentCause.icon!)) \(Text(commit.shortSha).font(.system(.footnote, design: .monospaced))) by \(commit.commitAuthorName) in \(commit.org)/\(commit.repo)")
							.foregroundStyle(.secondary)
							.font(.footnote.weight(.regular))
					}
				}.font(.headline)
			}

			LabelView("Status") {
				DeploymentStateIndicator(state: deployment.state)
			}

			if deployment.target == .production {
				Label("Production Deployment", systemImage: "theatermasks")
					.symbolVariant(.fill)
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
		DetailSection(header: Text("Deployment URL")) {
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
				HStack {
					Label("Deployment Aliases", systemImage: "arrowshape.turn.up.right")
					Spacer()
					Text("\(aliases.count)").foregroundColor(.secondary)
				}
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
	@Environment(\.presentationMode) var presentationMode
	@EnvironmentObject var session: VercelSession

	var accountId: VercelAccount.ID
	var deployment: VercelDeployment

	@State var cancelConfirmation = false
	@State var deleteConfirmation = false
	@State var redeployConfirmation = false

	@State var mutating = false
	@State var recentlyCancelled = false

	var body: some View {
		DetailSection(header: Text("Details")) {
			if let svnInfo = deployment.commit,
			   let commitUrl: URL = svnInfo.commitUrl,
			   let shortSha: String = svnInfo.shortSha
			{
				Link(destination: commitUrl) {
					Label("View Commit (\(Text(shortSha).font(.system(.body, design: .monospaced))))", image: svnInfo.provider.rawValue)
				}
				.contextMenu {
					Section {
						Button {
							Pasteboard.setString(deployment.commit?.commitSha)
						} label: {
							Text("Copy Commit Sha")
						}

						Button {
							Pasteboard.setString(commitUrl.absoluteString)
						} label: {
							Text("Copy Commit URL")
						}
					} header: {
						Label("Copy", systemImage: "doc.on.doc")
					}
				}
			}

			NavigationLink {
				DeploymentLogView(deployment: deployment, accountID: accountId)
					.environmentObject(session)
			} label: {
				Label("View Logs", systemImage: "terminal")
			}
			
			if let redeployPayload = deployment.redeployDataPayload {
				Button {
					redeployConfirmation = true
				} label: {
					Label("Redeploy", systemImage: "arrow.clockwise")
				}
				.disabled(mutating)
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
						primaryButton: .destructive(Text("Delete"), action: {
							Task { await deleteDeployment() }
						}),
						secondaryButton: .cancel()
					)
				}
				.disabled(mutating)
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
				.disabled(mutating)
				.alert(isPresented: $cancelConfirmation) {
					Alert(
						title: Text("Are you sure you want to cancel this deployment?"),
						message: Text("This will immediately stop the build, with no option to resume."),
						primaryButton: .destructive(Text("Cancel Deployment"), action: {
							Task { await cancelDeployment() }
						}),
						secondaryButton: .cancel(Text("Close"))
					)
				}
				.symbolRenderingMode(.multicolor)
			}
		}
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
			presentationMode.wrappedValue.dismiss()
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
					presentationMode.wrappedValue.dismiss()
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

private struct DetailSection<Content: View>: View {
	var header: Text
	var content: Content

	init(header: Text, @ViewBuilder content: @escaping () -> Content) {
		self.content = content()
		self.header = header
	}

	var body: some View {
		#if os(macOS)
			GroupBox(label: header) {
				HStack {
					VStack(alignment: .leading) {
						content
					}
					Spacer(minLength: 0)
				}
				.padding()
			}
		#else
			Section(header: header) {
				content
			}
		#endif
	}
}
