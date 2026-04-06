# Flutter BlackBox 🐞

[![pub package](https://img.shields.io/pub/v/flutter_blackbox.svg)](https://pub.dev/packages/flutter_blackbox)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

An all-in-one **In-App Debug & QA Overlay** for Flutter. One unified package to monitor network requests, inspect storage, track widget rebuilds, observe Socket.IO events, catch crashes, track performance, and generate comprehensive Markdown QA reports — all without modifying your existing code.

> **Zero Runtime Cost**: Designed exclusively for Debug and Profile modes. All debug code compiles out of Release builds via `kDebugMode`.

> **Observe Only, Never Modify**: BlackBox hooks into your existing libraries (Dio, http, Socket.IO, SharedPreferences) through their built-in extension points. Your trusted code stays completely untouched.

---

## 🚀 Features

| Panel | Description |
|-------|-------------|
| **🌐 Network** | Real-time HTTP/Dio request interception. Headers, payloads, status codes, error types (Timeout, Connection, Server). |
| **🎛 Mocking** | Intercept and replace API calls with local JSON responses. Simulate slow networks with throttle slider. |
| **📋 Logs** | Auto-captures all `debugPrint` and `print` output. Manual logging with levels and tags. |
| **⚡ Performance** | Live FPS graph, jank detection, memory alerts. |
| **🔄 Rebuilds** | Track widget rebuild counts — auto-detect ALL rebuilds or wrap specific widgets. Heat-colored ranking. |
| **💾 Storage** | Inspect, search, edit, and delete key-value pairs from SharedPreferences, GetStorage, Hive, or any storage. **Sensitive data auto-redacted.** |
| **🔌 Socket IO** | Auto-capture all incoming Socket.IO events via adapter. Zero code changes. |
| **📱 Device** | Device info, OS version, app version, connectivity status. |
| **🐛 Crashes** | Auto-catches framework errors, async exceptions, and unhandled crashes. |
| **🗺️ Journey** | Route changes and UI interactions logged to reconstruct what happened before a crash. |
| **📝 QA Reports** | One-tap Markdown reports with screenshots, device state, journey, network logs, and stack traces. |

---

## 📦 Installation

```yaml
dependencies:
  flutter_blackbox: ^0.1.4
```

---

## 🛠 Quick Start

```dart
import 'package:flutter/material.dart';
import 'package:flutter_blackbox/flutter_blackbox.dart';

void main() {
  BlackBox.setup(enabled: kDebugMode);
  runApp(BlackBoxOverlay(child: const MyApp()));
}
```

That's it — shake your device (or use a trigger) to open the overlay.

---

## 🌐 Network Adapters

BlackBox **observes** your network calls silently — no changes to your API code.

### Dio (recommended)

```dart
final dio = Dio();

BlackBox.setup(
  httpAdapters: [DioBlackBoxAdapter(dio)],
);

// Use dio exactly as before — BlackBox observes via interceptors
final response = await dio.get('/api/users');
```

### http package

```dart
final client = http.Client();

BlackBox.setup(
  httpAdapters: [HttpBlackBoxAdapter(client)],
);

// Use client exactly as before — BlackBox observes silently
final response = await client.get(Uri.parse('https://api.example.com'));
```

---

## 🔌 Socket.IO Adapter

Auto-captures **all incoming** Socket.IO events with zero code changes:

```dart
final socket = io.io('http://localhost:3000');

BlackBox.setup(
  socketAdapters: [SocketIOBlackBoxAdapter(socket)],
);

// Your existing socket code — completely untouched:
socket.on('message', (data) => handleMessage(data));
socket.on('notification', (data) => showNotification(data));
// ↑ All events appear in the Socket IO panel automatically
```

---

## 💾 Storage Inspector

Inspect any key-value storage — SharedPreferences, GetStorage, Hive, FlutterSecureStorage, etc.

### Built-in SharedPreferences adapter

```dart
BlackBox.setup(
  storageAdapters: [SharedPrefsStorageAdapter()],
);
```

### Custom adapter (GetStorage, Hive, etc.)

```dart
class GetStorageAdapter extends BlackBoxStorageAdapter {
  final GetStorage _box;
  GetStorageAdapter(this._box);

  @override String get name => 'GetStorage';
  @override Future<Map<String, dynamic>> readAll() async { ... }
  @override Future<void> write(String key, dynamic value) async => _box.write(key, value);
  @override Future<void> delete(String key) async => _box.remove(key);
  @override Future<void> clear() async => _box.erase();
}

// Use multiple adapters — each gets its own tab
BlackBox.setup(
  storageAdapters: [
    SharedPrefsStorageAdapter(),
    GetStorageAdapter(GetStorage()),
  ],
);
```

### 🔒 Privacy & Sensitive Data

**By default, sensitive keys are auto-redacted.** Keys matching patterns like `password`, `token`, `secret`, `jwt`, `pin`, `auth`, etc. show as `••••••••` — can't be copied or edited.

```dart
// Default: sensitive data is hidden (recommended)
BlackBox.setup(
  storageAdapters: [SharedPrefsStorageAdapter()],
  // redactSensitiveData: true  ← default
);

// Opt-in to show everything (internal dev builds only)
BlackBox.setup(
  storageAdapters: [SharedPrefsStorageAdapter()],
  redactSensitiveData: false,
);
```

**Customize per adapter:**

```dart
class MyAdapter extends BlackBoxStorageAdapter {
  @override
  List<String> get sensitiveKeyPatterns => [
    ...BlackBoxStorageAdapter.defaultSensitivePatterns,
    'credit_card',    // your custom patterns
    'bank_account',
  ];
}
```

---

## 🔄 Widget Rebuild Tracker

Track which widgets rebuild the most — find performance bottlenecks.

### Automatic mode (recommended)

Toggle "AUTO ON" in the Rebuilds panel — tracks ALL widget rebuilds automatically using Flutter's `debugPrintRebuildDirtyWidgets`. Zero code changes needed.

```dart
// Or enable programmatically:
BlackBox.startRebuildTracking();
```

### Manual mode (specific widgets)

```dart
// Wrap specific widgets for granular tracking
RebuildTracker(
  label: 'ProductCard',
  child: ProductCard(),
)
```

> **Release Safety**: `RebuildTracker` uses `kDebugMode` (compile-time constant) — the entire tracking code is eliminated by Dart's tree-shaker in release builds. Zero overhead, zero app size impact.

---

## 📋 Custom Logging

```dart
BlackBox.log('User tapped checkout', level: LogLevel.info, tag: 'Checkout');
BlackBox.log('Payment failed', level: LogLevel.error, tag: 'Payment', data: {'orderId': '123'});
```

> BlackBox automatically captures all `debugPrint` and `print` output — no manual logging required for those.

---

## 🎛 API Mocking

```dart
BlackBox.mock(
  pattern: '/api/v1/user/profile',
  method: 'GET',
  response: MockResponse(
    statusCode: 200,
    body: {'name': 'Alice', 'role': 'Admin'},
  ),
);
```

---

## 🎮 Panel Triggers

```dart
BlackBox.setup(
  trigger: BlackBoxTrigger.shake(),                          // Shake device
  // trigger: BlackBoxTrigger.hotkey(LogicalKeyboardKey.f12), // Desktop F12
  // trigger: BlackBoxTrigger.floatingButton(),               // Floating button
);
```

---

## ⚙️ Full Setup Example

```dart
import 'package:flutter_blackbox/flutter_blackbox.dart';

final dio = Dio();

void main() {
  BlackBox.setup(
    // Network — observe silently
    httpAdapters: [DioBlackBoxAdapter(dio)],

    // Socket — auto-capture incoming events
    // socketAdapters: [SocketIOBlackBoxAdapter(socket)],

    // Storage — inspect key-value stores
    storageAdapters: [SharedPrefsStorageAdapter()],

    // Logging
    logAdapter: PrintLogAdapter(),

    // Privacy — sensitive keys auto-redacted (default: true)
    redactSensitiveData: true,

    // Trigger
    trigger: const BlackBoxTrigger.floatingButton(),

    // Ignore specific noisy widgets from the Rebuild tab
    ignoredRebuildWidgets: ['MyAppThemeWrapper'],

    // Only in debug mode
    enabled: kDebugMode,
  );

  runApp(const BlackBoxOverlay(child: MyApp()));
}
```

---

## 📝 QA Reports

Tap the **QA** tab → provide a bug name → tap **Generate Report**. BlackBox compiles a Markdown report with:

- 📸 Screenshot
- 📱 Device info (OS, model, DPI, connectivity)
- 🗺️ User journey (routes + taps)
- 🌐 Failed network requests
- 🔌 Socket events
- 📋 Recent logs
- 🐛 Crash stack traces

One tap **Copy** → paste directly into GitHub Issues, Jira, or Slack.

---

## 📄 License

MIT.
# flutter_blackbox
