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

	@State var filter = DeploymentFilter()
	@State var productionFilter = false
	@State var filterVisible = false
	@State var pagination: Pagination?

	@State private var deployments: [VercelDeployment] = []

	var accountId: String {
		session.account.id
	}

	var body: some View {
		ZStack {
			List {
				ForEach(deployments) { deployment in
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
			.onChange(of: filter) { _ in
				Task {
					try? await loadDeployments()
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
				.symbolVariant(filter.filtersApplied ? .fill : .none)
			}
			.sheet(isPresented: self.$filterVisible) {
				#if os(iOS)
				if #available(iOS 16.0, *) {
					DeploymentFilterView(filter: $filter)
						.presentationDetents([.medium])
				} else {
					DeploymentFilterView(filter: $filter)
				}
				#else
				DeploymentFilterView(filter: $filter)
				#endif
			}
			
			if deployments.isEmpty && filter.filtersApplied {
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
		var params: [URLQueryItem] = filter.urlQueryItems

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
		filter = .init()
	}
}
