//
//  PostalService.swift
//  Zeitgeist
//
//  Created by Daniel Eden on 05/06/2021.
//

import Foundation

enum ZPSError: Error {
	case FieldCastingError(field: Any?)
	case EventTypeCastingError(eventType: Any?)
}

enum ZPSEventType: String {
	case deployment
	case deploymentReady = "deployment-ready"
	case deploymentError = "deployment-error"
	case deploymentCanceled = "deployment-canceled"
	case projectCreated = "project-created"
	case projectRemoved = "project-removed"

	var emojiPrefix: String {
		switch self {
		case .deployment:
			return "⏱ "
		case .deploymentReady:
			return "✅ "
		case .deploymentError:
			return "🛑 "
		case .deploymentCanceled:
			return "🚫 "
		case .projectCreated:
			return "📂 "
		case .projectRemoved:
			return "🗑 "
		}
	}

	var associatedState: VercelDeployment.State? {
		switch self {
		case .deployment:
			return .building
		case .deploymentReady:
			return .ready
		case .deploymentError:
			return .error
		case .deploymentCanceled:
			return .cancelled
		default:
			return nil
		}
	}
}

enum ZPSNotificationCategory: String {
	case deployment, project
}
