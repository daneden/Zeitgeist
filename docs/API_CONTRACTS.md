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
| `platform`  | string | Yes      | `ios`, `ios_sandbox`, `macos` or `macos_sandbox` (the `_sandbox` values are debug builds) |

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

## Notification Settings Sync

### `POST /api/notificationPreferences`

Sends the device's notification settings and the accounts it is signed into. `NotificationSync` calls it when the token, the accounts or a setting changes, when the app becomes active after a failed sync, and at least once a day. From the first successful sync the server filters events for the device and sends alert pushes (see below); until then the device gets the legacy background payload.

The server also makes the token's registrations match `accounts`: it registers the token under each listed account and removes it from any other, so signing out stops that account's pushes.

**Body:**

```json
{
  "device_id": "<hex APNs token>",
  "platform": "ios" | "ios_sandbox" | "macos" | "macos_sandbox",
  "accounts": ["team_…", "…"],
  "preferences": {
    "building": ["prj_…"],
    "error": ["prj_…"],
    "ready": ["prj_…"],
    "productionOnly": ["prj_…"],
    "emoji": false,
    "grouping": "account" | "project" | "deployment"
  }
}
```

**Response:** `{ "status": "preferences_synced" }`, or `400 { "success": false, "error": "…" }`.

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

## Push Notification Payloads

The server sends one push per device for each event. Its shape depends on whether the device has synced its settings.

### Alert push (synced devices, events the user enabled)

A visible alert with `content-available`, so the app also wakes to refresh. The system localizes the text from the app's string catalog; the app never posts its own notification for it.

```json
{
  "aps": {
    "alert": {
      "title-loc-key": "%@Deployment ready for %@",
      "title-loc-args": ["✅ ", "my-app"],
      "loc-key": "Caused by %@'s commit \"%@\"",
      "loc-args": ["author", "first line of the commit message"]
    },
    "content-available": 1,
    "sound": "default",
    "category": "deployment",
    "thread-id": "<from the grouping setting>"
  },
  "zps": 2,
  "eventType": "deployment-ready",
  "projectId": "prj_…",
  "deploymentId": "dpl_…",
  "teamId": "team_…",
  "userId": "…",
  "target": "production"
}
```

`apns-collapse-id` is `{thread-id}-{eventType}`, the same identifier the app gives its own notifications.

### Background push (synced devices, all other events)

`{ "aps": { "content-available": 1 }, "zps": 2, … }` with the same custom keys, priority 5 and `apns-expiration: 0`. `zps` tells the app that the server already decided, so it only refreshes.

### Legacy background push (devices that have not synced)

The app filters these itself and posts a local notification. They are received in `application(_:didReceiveRemoteNotification:)`. Mac devices that have not synced get no push.

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
| `deployment-canceled` | Deployment canceled |
| `project.created` / `project.removed` | Project events; refresh only, never an alert |

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
   └─> Synced device: server sends an alert push if the settings allow the event, else a background push
   └─> Other devices: server sends the legacy background push
   └─> App receives in didReceiveRemoteNotification and refreshes
   └─> Legacy push only: app creates local notification + Live Activity
   └─> ActivityKit provides push token
   └─> App registers token with /api/registerLiveActivityToken

3. Deployment Progress/Completion (server receives Vercel webhook)
   └─> Server sends APNS push to activity token
   └─> iOS automatically updates Live Activity UI
   └─> For terminal states, activity ends after dismissal-date
```
