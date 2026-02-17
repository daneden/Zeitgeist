//
//  AccountManagementButton.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 17/02/2026.
//

import SwiftUI

struct AccountManagementButton: View {
	@Environment(\.session) private var session
	
	@State private var showAccountManagementView = false
	
    var body: some View {
			if let selectedAccount = session?.account {
				Button {
					showAccountManagementView = true
				} label: {
					HStack {
						VercelUserAvatarView(account: selectedAccount, size: 24)
							.id(selectedAccount.id)
							.transition(.opacity)
						
						VStack(alignment: .leading) {
							Text(verbatim: selectedAccount.name ?? selectedAccount.username)
								.font(.footnote)
								.fontWeight(.medium)
							Text("Manage accounts")
								.font(.caption)
								.foregroundStyle(.secondary)
						}
						
						Spacer()
						
						Image(systemName: "arrow.forward")
							.symbolVariant(.circle.fill)
							.symbolRenderingMode(.monochrome)
							.foregroundStyle(.tertiary)
					}
					.contentTransition(.numericText())
				}
				.buttonStyle(.bordered)
				.buttonBorderShape(.capsule)
				.sheet(isPresented: $showAccountManagementView) {
					AccountManagementView()
					#if os(macOS)
						.modify {
							if #available(macOS 15, *) {
								$0.presentationSizing(.form)
							} else {
								$0.frame(minHeight: 400)
							}
						}
					#endif
				}
			}
    }
}

#Preview {
    AccountManagementButton()
}
