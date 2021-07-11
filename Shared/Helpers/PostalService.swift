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

enum ZPSEventType: String, RawRepresentable {
  case Deployment = "deployment"
  case DeploymentReady = "deployment-ready"
  case DeploymentError = "deployment-error"
}

struct ZPSNotificationPayload: Hashable {
  let deploymentId: String
  let userId: String
  let title: String?
  let body: String
  let category: ZPSEventType
}

enum ZPSNotificationCategory: String, RawRepresentable {
  case Deployment
}
