//
//  VercelSession+accountCRUD.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 23/09/2022.
//

import Foundation
import SwiftUI

extension VercelSession {
	static func addAccount(id: String, token: String) async {
		guard id != .NullValue else { return }
		
		KeychainItem(account: id).wrappedValue = token
		
		let urlString = "https://api.vercel.com/v2/\(id.isTeam ? "teams/\(id)?teamId=\(id)" : "user")"
		var request = URLRequest(url: URL(string: urlString)!)
		
		do {
			request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
			let (data, _) = try await URLSession.shared.data(for: request)
			let decoded = try JSONDecoder().decode(VercelAccount.self, from: data)
			
			DispatchQueue.main.async { [decoded] in
				withAnimation {
					if let index = Preferences.accounts.firstIndex(where: { $0.id == decoded.id }) {
						Preferences.accounts[index] = decoded
					} else {
						Preferences.accounts.append(decoded)
					}
				}
				
				NotificationCenter.default.post(Notification(name: .VercelAccountAddedNotification))
			}
			
			#if os(iOS)
			await UIApplication.shared.registerForRemoteNotifications()
			#elseif os(macOS)
			await NSApplication.shared.registerForRemoteNotifications()
			#endif
		} catch {
			print("Encountered an error when adding account with ID \(id)")
			print(error)
		}
	}
	
	static func deleteAccount(id: String) {
		let keychain = KeychainItem(account: id)
		keychain.wrappedValue = nil
		
		guard let accountIndex = Preferences.accounts.firstIndex(where: { $0.id == id }) else {
			return
		}
		
		NotificationCenter.default.post(name: .VercelAccountWillBeRemovedNotification, object: accountIndex)
		
		withAnimation {
			_ = Preferences.accounts.remove(at: accountIndex)
		}
	}
}

