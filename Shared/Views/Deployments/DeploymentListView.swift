//
//  DeploymentListView.swift
//  Verdant
//
//  Created by Daniel Eden on 30/05/2021.
//

import Combine
import SwiftUI

struct DeploymentListView: View {
	@EnvironmentObject var session: VercelSession

	@State var stateFilter: StateFilter = .allStates
	@State var productionFilter = false
	@State var filterVisible = false
	@State var pagination: Pagination?

	@State private var deployments: [VercelDeployment] = []

	private var filteredDeployments: [VercelDeployment] {
		return deployments.filter { deployment -> Bool in
			switch self.stateFilter {
			case .allStates:
				return true
			case let .filteredByState(state):
				return state == deployment.state
			}
		}
		.filter { deployment -> Bool in
			productionFilter ? deployment.target == .production : true
		}
	}

	var filtersApplied: Bool {
		stateFilter != .allStates || productionFilter == true
	}

	var accountId: String {
		session.account.id
	}

	var body: some View {
		ZStack {
			List {
				ForEach(filteredDeployments) { deployment in
					NavigationLink {
						DeploymentDetailView(deployment: deployment)
							.environmentObject(session)
					} label: {
						DeploymentListRowView(deployment: deployment)
					}
				}

				if let pageId = pagination?.next {
					LoadingListCell(title: "Loading Deployments")
						.task {
							do {
								try await loadDeployments(pageId: pageId)
							} catch {
								print(error)
							}
						}
				}
			}
			.dataTask {
				try? await loadDeployments()
			}
			.toolbar {
				Button(action: { self.filterVisible.toggle() }) {
					Label("Filter Deployments", systemImage: "line.horizontal.3.decrease.circle")
				}
				.keyboardShortcut("l", modifiers: .command)
				.symbolVariant(filtersApplied ? .fill : .none)
			}
			.sheet(isPresented: self.$filterVisible) {
#if os(iOS)
				NavigationView {
					DeploymentFilterView(
						stateFilter: self.$stateFilter,
						productionFilter: self.$productionFilter
					)
				}
#else
				DeploymentFilterView(
					stateFilter: self.$stateFilter,
					productionFilter: self.$productionFilter
				)
#endif
			}
			
			if filteredDeployments.isEmpty && !deployments.isEmpty {
				VStack(spacing: 8) {
					Spacer()
					
					PlaceholderView(forRole: .NoDeployments)
					
					Button(action: clearFilters) {
						Label("Clear Filters", systemImage: "xmark.circle")
					}
					
					Spacer()
				}
			} else if deployments.isEmpty {
				PlaceholderView(forRole: .NoDeployments)
			}
		}
		.navigationTitle("Deployments")
		.permissionRevocationDialog(session: session)
	}

	func loadDeployments(pageId: Int? = nil) async throws {
		var params: [URLQueryItem] = []

		if let pageId = pageId {
			params.append(URLQueryItem(name: "from", value: String(pageId - 1)))
		}

		var request = VercelAPI.request(for: .deployments(), with: session.account.id, queryItems: params)
		try session.signRequest(&request)

		if pageId == nil,
		   let cachedResponse = URLCache.shared.cachedResponse(for: request),
		   let decodedFromCache = try? JSONDecoder().decode(VercelDeployment.APIResponse.self, from: cachedResponse.data)
		{
			deployments = decodedFromCache.deployments
		}

		let (data, response) = try await URLSession.shared.data(for: request)
		session.validateResponse(response)
		let decoded = try JSONDecoder().decode(VercelDeployment.APIResponse.self, from: data)
		withAnimation {
			if pageId != nil {
				self.deployments.append(contentsOf: decoded.deployments)
			} else {
				self.deployments = decoded.deployments
			}

			self.pagination = decoded.pagination
		}
	}

	func clearFilters() {
		stateFilter = .allStates
		productionFilter = false
	}
}
