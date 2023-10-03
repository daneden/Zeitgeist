//
//  SignInViewModel.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 01/01/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import AuthenticationServices
import Combine
import Foundation
import SwiftUI

class VercelAPIConfiguration: Codable {
	public let clientId: String = "oac_j50L1tLSVzBpEv1gXEVDdR3g"

	public enum CodingKeys: String, CodingKey {
		case clientId = "client_id"
	}
}

class VercelURLAuthenticationBuilder {
	let domain: String
	let clientID: String
	let uid = UUID()

	init(domain: String = "vercel.com", clientID: String) {
		self.domain = domain
		self.clientID = clientID
	}

	var url: URL {
		var components = URLComponents()
		components.scheme = "https"
		components.host = domain
		components.path = "/integrations/zeitgeist/new"
		components.queryItems = [
			"client_id": clientID,
			"v": "2",
		].map { URLQueryItem(name: $0, value: $1) }

		return components.url!
	}

	func callAsFunction() -> URL {
		url
	}
}

class SignInViewModel: NSObject, ObservableObject, ASWebAuthenticationPresentationContextProviding {
	private(set) var isSigningIn = false
	private var subscriptions: [AnyCancellable] = []

	func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
		return ASPresentationAnchor()
	}

	@MainActor
	func signIn() {
		self.isSigningIn = true
		
		let signInPromise = Future<URL, Error> { completion in
			let apiData = VercelAPIConfiguration()
			let authUrl = VercelURLAuthenticationBuilder(clientID: apiData.clientId)()

			let authSession = ASWebAuthenticationSession(url: authUrl, callbackURLScheme: "https") { url, error in
				if let error = error {
					completion(.failure(error))
				} else if let url = url {
					completion(.success(url))
				}
			}

			authSession.presentationContextProvider = self
			authSession.start()
		}

		signInPromise.sink { completion in
			self.isSigningIn = false
			
			switch completion {
			case let .failure(error):
				print("auth failed for reason: \(error)")
			default: break
			}
		} receiveValue: { url in
			self.processResponseURL(url: url)
		}
		.store(in: &subscriptions)
	}

	@MainActor
	func processResponseURL(url: URL) {
		let components = URLComponents(url: url, resolvingAgainstBaseURL: true)

		if let queryItems = components?.queryItems,
		   let token = queryItems.filter({ $0.name == "token" }).first?.value
		{
			let teamId = queryItems.filter { $0.name == "teamId" }.first?.value ?? nil
			let userId = queryItems.filter { $0.name == "userId" }.first?.value ?? nil

			Task {
				await VercelSession.addAccount(id: teamId ?? userId ?? VercelAccount.ID.NullValue, token: token)
			}
		} else {
			print("Something went wrong!")
		}
	}
}
