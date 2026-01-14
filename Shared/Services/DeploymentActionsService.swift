//
//  DeploymentActionsService.swift
//  Zeitgeist
//
//  Created by Claude on 2026-01-12.
//

import Foundation

@Observable
@MainActor
final class DeploymentActionsService {
	var isMutating = false
	var recentlyCancelled = false

	private(set) var id = UUID()
	
	private let session: VercelSession
	private let accountId: VercelAccount.ID

	init(session: VercelSession, accountId: VercelAccount.ID) {
		self.session = session
		self.accountId = accountId
		self.id = UUID()
	}

	// MARK: - Promote to Production

	/// Promotes a deployment to production using the deployment's data payload
	@discardableResult
	func promoteToProduction(_ deployment: VercelDeployment) async -> Bool {
		guard let data = deployment.promoteToProductionDataPayload else { return false }
		isMutating = true
		defer { isMutating = false }

		do {
			var request = VercelAPI.request(for: .deployments(version: 13), with: accountId, method: .POST)
			request.httpBody = data
			try session.signRequest(&request)

			let _ = try await URLSession.shared.data(for: request)
			return true
		} catch {
			print("Error promoting to production: \(error)")
			return false
		}
	}

	/// Promotes a staging or previous production deployment to production using the project promote endpoint
	@discardableResult
	func promoteStagingToProduction(_ deployment: VercelDeployment, project: VercelProject) async -> Bool {
		isMutating = true
		defer { isMutating = false }

		do {
			var request = VercelAPI.request(
				for: .projects(version: 10, project.id, path: "promote/\(deployment.id)"),
				with: accountId,
				method: .POST
			)
			try session.signRequest(&request)

			let _ = try await URLSession.shared.data(for: request)
			return true
		} catch {
			print("Error promoting staging deployment: \(error)")
			return false
		}
	}

	// MARK: - Instant Rollback

	/// Performs instant rollback to a previous production deployment
	@discardableResult
	func instantRollback(_ deployment: VercelDeployment, project: VercelProject) async -> Bool {
		isMutating = true
		defer { isMutating = false }

		do {
			var request = VercelAPI.request(
				for: .projects(version: 10, project.id, path: "promote/\(deployment.id)"),
				with: accountId,
				method: .POST
			)
			try session.signRequest(&request)

			let _ = try await URLSession.shared.data(for: request)
			return true
		} catch {
			print("Error performing instant rollback: \(error)")
			return false
		}
	}

	// MARK: - Redeploy

	/// Redeploys a deployment, optionally using the existing build cache
	@discardableResult
	func redeploy(_ deployment: VercelDeployment, withCache: Bool = false) async -> Bool {
		guard let data = deployment.redeployDataPayload else { return false }
		isMutating = true
		defer { isMutating = false }

		do {
			var queryItems = [URLQueryItem(name: "forceBuild", value: "1")]

			if withCache {
				queryItems.append(URLQueryItem(name: "withCache", value: "1"))
			}

			var request = VercelAPI.request(for: .deployments(version: 13), with: accountId, queryItems: queryItems, method: .POST)
			request.httpBody = data
			try session.signRequest(&request)

			let _ = try await URLSession.shared.data(for: request)
			return true
		} catch {
			print("Error redeploying: \(error)")
			return false
		}
	}

	// MARK: - Delete Deployment

	/// Deletes a deployment
	@discardableResult
	func deleteDeployment(_ deployment: VercelDeployment) async -> Bool {
		isMutating = true
		defer { isMutating = false }

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
				return true
			}
			return false
		} catch {
			print("Error deleting deployment: \(error.localizedDescription)")
			return false
		}
	}

	// MARK: - Cancel Deployment

	/// Cancels a queued or building deployment
	@discardableResult
	func cancelDeployment(_ deployment: VercelDeployment) async -> Bool {
		isMutating = true
		defer { isMutating = false }

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
				return true
			}
			return false
		} catch {
			print("Error cancelling deployment: \(error.localizedDescription)")
			return false
		}
	}
}
