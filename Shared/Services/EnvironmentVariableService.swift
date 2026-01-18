//
//  EnvironmentVariableService.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 17/01/2026.
//

import Foundation

/// Centralized service for environment variable API operations.
/// Use this to avoid duplicating API logic across iOS and macOS views.
enum EnvironmentVariableService {

    /// Fetches all environment variables for a project.
		@MainActor
    static func fetchAll(projectId: VercelProject.ID, session: VercelSession) async throws -> [VercelEnv] {
        var request = VercelAPI.request(for: .projects(projectId, path: "env"), with: session.account.id)
        try session.signRequest(&request)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(VercelEnv.APIResponse.self, from: data).envs
    }

    /// Fetches a single environment variable with its decrypted value.
    @MainActor
		static func fetchDecrypted(projectId: VercelProject.ID, envVarId: VercelEnv.ID, session: VercelSession) async throws -> VercelEnv {
        var request = VercelAPI.request(for: .projects(projectId, path: "env/\(envVarId)"), with: session.account.id)
        try session.signRequest(&request)

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(VercelEnv.self, from: data)
    }

    /// Creates a new environment variable.
    @MainActor
		static func create(
        projectId: VercelProject.ID,
        key: String,
        value: String,
        targets: [String],
        session: VercelSession
    ) async throws -> VercelEnv {
        var request = VercelAPI.request(for: .projects(projectId, path: "env"), with: session.account.id, method: .POST)

        let body: [String: Any] = [
            "key": key,
            "value": value,
            "target": targets,
            "type": "encrypted"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        try session.signRequest(&request)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(VercelEnv.self, from: data)
    }

    /// Updates an existing environment variable.
    @MainActor
		static func update(
        projectId: VercelProject.ID,
        envVarId: VercelEnv.ID,
        key: String,
        value: String,
        targets: [String],
        session: VercelSession
    ) async throws -> VercelEnv {
        var request = VercelAPI.request(for: .projects(projectId, path: "env/\(envVarId)"), with: session.account.id, method: .PATCH)

        let body: [String: Any] = [
            "key": key,
            "value": value,
            "target": targets,
            "type": "encrypted"
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        try session.signRequest(&request)
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(VercelEnv.self, from: data)
    }

    /// Deletes an environment variable.
    @MainActor
		static func delete(projectId: VercelProject.ID, envVarId: VercelEnv.ID, session: VercelSession) async throws {
        var request = VercelAPI.request(for: .projects(projectId, path: "env/\(envVarId)"), with: session.account.id, method: .DELETE)
        try session.signRequest(&request)

        _ = try await URLSession.shared.data(for: request)
    }

    /// Convenience: Build targets array from booleans
		static func buildTargets(production: Bool, preview: Bool, development: Bool) -> [String] {
        var targets = [String]()
        if production { targets.append("production") }
        if preview { targets.append("preview") }
        if development { targets.append("development") }
        return targets
    }
}
