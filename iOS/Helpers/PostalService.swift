//
//  PostalService.swift
//  iOS
//
//  Created by Daniel Eden on 17/03/2021.
//  Copyright © 2021 Daniel Eden. All rights reserved.
//

import Foundation
import SwiftUI

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
