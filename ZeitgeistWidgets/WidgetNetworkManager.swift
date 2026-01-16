//
//  WidgetNetworkManager.swift
//  ZeitgeistWidgets
//
//  Created by Claude on 2026-01-16.
//

import Foundation
import OSLog

/// Manages network requests for widget extensions.
final class WidgetNetworkManager {
	static let shared = WidgetNetworkManager()

	private static let logger = Logger(
		subsystem: "me.daneden.Zeitgeist.ZeitgeistWidgets",
		category: String(describing: WidgetNetworkManager.self)
	)

	/// URLSession configured for widget network requests
	private lazy var session: URLSession = {
		let config = URLSessionConfiguration.default
		config.timeoutIntervalForRequest = 15
		config.timeoutIntervalForResource = 30
		config.waitsForConnectivity = true
		return URLSession(configuration: config)
	}()

	private init() {}

	/// Fetches data for the given request.
	func fetchData(for request: URLRequest) async throws -> (Data, URLResponse) {
		Self.logger.debug("Starting fetch for: \(request.url?.absoluteString ?? "unknown")")
		return try await session.data(for: request)
	}
}

// MARK: - Deployment Fetching

extension WidgetNetworkManager {
	/// Token store for retrieving authentication tokens
	private static let tokenStore: TokenStore = KeychainTokenStore()

	/// Signs a request with the authentication token for the given account.
	/// - Parameters:
	///   - request: The request to sign
	///   - accountId: The account ID to authenticate as
	/// - Returns: True if signing succeeded, false if no token was found
	private func signRequest(_ request: inout URLRequest, for accountId: String) -> Bool {
		guard let token = Self.tokenStore.getToken(for: accountId) else {
			Self.logger.warning("No token found for account \(accountId)")
			return false
		}
		request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
		return true
	}

	/// Fetches deployments for the given account and configuration.
	/// Returns nil if the request fails.
	func fetchDeployments(
		account: VercelAccount,
		projectId: String?,
		productionOnly: Bool
	) async -> [VercelDeployment]? {
		guard Self.tokenStore.hasToken(for: account.id) else {
			Self.logger.warning("No valid token for account \(account.id)")
			return nil
		}

		var queryItems: [URLQueryItem] = []

		if let projectId = projectId {
			queryItems.append(URLQueryItem(name: "projectId", value: projectId))
		}

		if productionOnly {
			queryItems.append(URLQueryItem(name: "target", value: "production"))
		}

		var request = VercelAPI.request(for: .deployments(), with: account.id, queryItems: queryItems)

		guard signRequest(&request, for: account.id) else {
			return nil
		}

		do {
			let (data, _) = try await fetchData(for: request)
			let response = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data)
			Self.logger.debug("Fetched \(response.deployments.count) deployments")
			return response.deployments
		} catch {
			Self.logger.error("Failed to fetch deployments: \(error.localizedDescription)")
			return nil
		}
	}
}
