# API Contracts

This document defines the API contracts that the Zeitgeist iOS app uses to communicate with the backend server.

## Base URL

- **Production:** `https://zeitgeist.link`

---

## Push Notification Registration

### `GET /api/registerPushNotifications`

Registers a device for push notifications. Called when the app receives a device token from APNS.

**Query Parameters:**

| Parameter   | Type   | Required | Description |
|-------------|--------|----------|-------------|
| `user_id`   | string | Yes      | Vercel user ID or team ID |
| `device_id` | string | Yes      | APNS device token (hex string) |
| `platform`  | string | Yes      | `ios` or `ios_sandbox` |

**Example:**
```swift
let url = URL(string: "https://zeitgeist.link/api/registerPushNotifications?user_id=\(account.id)&device_id=\(token)&platform=\(platform)")!
```

**Response:**
```json
{
  "status": "new_user_registered" | "device_already_registered"
}
```

---

## Live Activity Token Registration

### `POST /api/registerLiveActivityToken`

Registers a Live Activity push token for remote updates. Called after starting a local Live Activity when ActivityKit provides a push token.

**Request:**
```swift
var request = URLRequest(url: URL(string: "https://zeitgeist.link/api/registerLiveActivityToken")!)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try JSONSerialization.data(withJSONObject: [
    "activityToken": tokenString,
    "deviceId": deviceId,
    "deploymentId": deploymentId,
    "projectId": projectId,
    "platform": platform
])
```

**Request Body:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `activityToken` | string | Yes | ActivityKit push token (hex string) |
| `deviceId` | string | Yes | Device's APNS token |
| `deploymentId` | string | Yes | Vercel deployment ID |
| `projectId` | string | Yes | Vercel project ID |
| `platform` | string | No | `ios` or `ios_sandbox` |

**Response:**
```json
{
  "success": true
}
```

---

## Background Push Notification Payload

The server sends background push notifications when deployment events occur. These are received in `application(_:didReceiveRemoteNotification:)`.

**Payload Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `title` | string? | Notification title (optional) |
| `body` | string | Notification body |
| `userId` | string? | Vercel user ID |
| `teamId` | string? | Vercel team ID |
| `deploymentId` | string? | Vercel deployment ID |
| `projectId` | string | Vercel project ID |
| `eventType` | string | Event type (see below) |
| `target` | string? | `production` or `staging` |

**Event Types:**

| Event Type | Description |
|------------|-------------|
| `deployment` | Build started |
| `deployment-ready` | Deployment succeeded |
| `deployment-error` | Build failed |

---

## Live Activity Push Payloads

After registering a Live Activity token, the server sends APNS pushes to update the activity remotely.

### Update Event

Sent when deployment status changes (e.g., build progress):

```json
{
  "aps": {
    "timestamp": 1704067200,
    "event": "update",
    "content-state": {
      "status": "building",
      "progress": 50
    }
  }
}
```

### End Event

Sent when deployment reaches a terminal state (ready, error, canceled):

```json
{
  "aps": {
    "timestamp": 1704067200,
    "event": "end",
    "content-state": {
      "status": "ready",
      "progress": 100
    },
    "dismissal-date": 1704067500
  }
}
```

---

## ContentState Schema

The `content-state` in Live Activity pushes is decoded into `DeploymentAttributes.ContentState`:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `status` | string | Yes | `building`, `ready`, `error`, or `canceled` |
| `progress` | number | No | Build progress 0-100 |
| `errorMessage` | string | No | Error description |

**Swift Implementation:**

The ContentState uses custom `Codable` to map the server's `status` field to the app's `deploymentState`:

```swift
struct ContentState: Codable & Hashable {
    let deploymentState: VercelDeployment.State
    let progress: Int?
    let errorMessage: String?

    enum CodingKeys: String, CodingKey {
        case status, progress, errorMessage
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let statusString = try container.decode(String.self, forKey: .status)
        self.deploymentState = VercelDeployment.State(rawValue: statusString) ?? .building
        self.progress = try container.decodeIfPresent(Int.self, forKey: .progress)
        self.errorMessage = try container.decodeIfPresent(String.self, forKey: .errorMessage)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deploymentState.rawValue, forKey: .status)
        try container.encodeIfPresent(progress, forKey: .progress)
        try container.encodeIfPresent(errorMessage, forKey: .errorMessage)
    }
}
```

---

## Status Mappings

| Server Status | iOS `VercelDeployment.State` |
|---------------|------------------------------|
| `building` | `.building` |
| `ready` | `.ready` |
| `error` | `.error` |
| `canceled` | `.cancelled` |

---

## Data Flow

```
1. App Launch
   └─> Register device token with /api/registerPushNotifications

2. Deployment Started (server receives Vercel webhook)
   └─> Server sends background push to device
   └─> App receives in didReceiveRemoteNotification
   └─> App creates local notification + Live Activity
   └─> ActivityKit provides push token
   └─> App registers token with /api/registerLiveActivityToken

3. Deployment Progress/Completion (server receives Vercel webhook)
   └─> Server sends APNS push to activity token
   └─> iOS automatically updates Live Activity UI
   └─> For terminal states, activity ends after dismissal-date
```
