//
//  MigrationHelpers.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 17/08/2022.
//

import Foundation
import SwiftUI

struct MigrationHelpers {
	struct V3 {
		@AppStorage(Preferences.authenticatedAccountIds) static var authenticatedAccountIds
		@AppStorage(Preferences.authenticatedAccounts) static var authenticatedAccounts
		
		static var needsMigration: Bool {
			!authenticatedAccountIds.isEmpty
		}
		
		static func migrateAccountIdsToAccounts() async {
			let accounts: [VercelAccount] = await Array(Set(authenticatedAccountIds)).asyncMap { id in
				guard let token = KeychainItem(account: id).wrappedValue else {
					return nil
				}
				
				do {
					var request = VercelAPI.request(for: .account(id: id), with: id)
					request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

					let (data, _) = try await URLSession.shared.data(for: request)

					return try JSONDecoder().decode(VercelAccount.self, from: data)
				} catch {
					print(error)
					return nil
				}
				
			}.compactMap { $0 }
			
			authenticatedAccounts += accounts
			authenticatedAccountIds = []
		}
	}
}
