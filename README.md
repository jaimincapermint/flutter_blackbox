# Flutter Blackbox 🐞

[![pub package](https://img.shields.io/pub/v/flutter_blackbox.svg)](https://pub.dev/packages/flutter_blackbox)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

An all-in-one, zero-dependency **In-App Debug & QA Overlay** for Flutter. One unified package to monitor network requests, mock responses, trace user journeys, catch crashes, track performance, and generate comprehensive Markdown QA reports on the fly. 

> **Zero Runtime Cost**: Designed exclusively for Debug and Profile modes. Include it securely knowing it compiles out of your Release builds (`kReleaseMode`).

---

## 🚀 Features

- **🌐 Network Inspector:** Real-time interception of HTTP/Dio requests. View headers, payloads, status codes, and precise error types (Timeout, Connection, Server, Format).
- **🎛 Mocking & Throttling:** Intercept and replace API calls with local JSON responses on the fly. Simulate slow networks using the built-in Delay Throttle slider.
- **🐛 Crash & Exception Logger:** Automatically catches framework layout errors, asynchronous exceptions, and unhandled crashes, storing them for QA.
- **🗺️ User Journey Tracking:** Automatically logs Route changes and UI pointer inputs to reconstruct exactly what the tester did before a crash.
- **📋 Automated QA Reports:** One-tap export to generate pristine Markdown bug reports containing the active screen snapshot, device state, feature flags, journey history, network logs, and error stack traces.
- **⚡ Performance Monitor:** Live FPS graphs, memory alerts, and jank detection warnings.
- **⚙️ Feature Flags:** Built-in dynamic toggles to turn experimental UI/logic branches on or off without restarting.

---

## 📦 Installation

Add `flutter_blackbox` to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_blackbox: ^0.1.0
```

*Note: BlackBox bundles native Http and Dio adapters automatically—no companion packages are needed!*

---

## 🛠 Setup & Usage

Initializing BlackBox requires exactly two lines of code.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_blackbox/flutter_blackbox.dart';

void main() {
  // 1. Initialize the singleton
  BlackBox.setup(enabled: !kReleaseMode);

  runApp(
    // 2. Wrap your root app to supply the floating panels
    BlackBoxOverlay(
      child: const MyApp(),
    ),
  );
}
```

### 1. Network Integrations

BlackBox supports seamless integration into your existing networking stack. 

**Using Dio:**
```dart
final dio = Dio();

BlackBox.setup(
  httpAdapters: [DioBlackBoxAdapter(dio)],
  enabled: kDebugMode,
);
```

**Using the generic Http package:**
Replace standard `http.Client()` invocations with `BlackBoxHttpClient()`:
```dart
BlackBox.setup(
  httpAdapters: [HttpBlackBoxAdapter()],
  enabled: kDebugMode,
);

final client = BlackBoxHttpClient();
final response = await client.get(Uri.parse('https://api.example.com/data'));
```

### 2. Feature Flags

Declare flag templates during setup and listen to realtime updates in your UI:

```dart
BlackBox.setup(
  flagAdapter: LocalFlagAdapter(flags: {
    'new_checkout_flow': FlagConfig(defaultValue: false, group: 'UI'),
    'api_url': FlagConfig(defaultValue: 'https://api.staging.com', group: 'Network'),
  }),
);

// In your Widgets: Read statically...
final isNewCheckout = BlackBox.flag<bool>('new_checkout_flow');

// ...or rebuild dynamically when toggled directly from the BlackBox panel!
BlackBox.flagStream<bool>('new_checkout_flow').listen((value) => setState(() {}));
```

### 3. Emitting Custom Logs

If you'd like to trace explicit debug messages through the BlackBox logger ecosystem:

```dart
BlackBox.log('User tapped the checkout button', level: LogLevel.info, tag: 'Checkout');
```
*(By default, BlackBox automatically captures all `debugPrint` and `print` outputs into its Log Panel).*

### 4. Mocking APIs

Turn specific network routes into completely offline simulations instantly. You can enable or disable these mock engines on the fly from the Network Panel.

```dart
BlackBox.mock(
  pattern: '/api/v1/user/profile', // String or RegExp matching
  method: 'GET',
  response: MockResponse(
    statusCode: 200,
    body: {'name': 'Alice', 'role': 'Admin'},
  ),
);
```
*(Tip: Tap the "Speed" icon in the Network Panel to add simulated artificial Throttle Delays up to 5000ms to your mocks!)*

---

## 🎮 Panel Triggers

How do you open BlackBox on a physical device once installed? You dictate the trigger gesture!

```dart
BlackBox.setup(
  trigger: BlackBoxTrigger.shake(),                         // Open on physically shaking the phone
  // trigger: BlackBoxTrigger.hotkey(LogicalKeyboardKey.f12),  // Desktop/Web F12 shortcut
  // trigger: BlackBoxTrigger.floatingButton(),                // A persistent drag-and-drop floating badge
);
```

## 📝 The QA Markdown Report

The most powerful feature of BlackBox natively exists in its `"QA"` tab.
If a tester taps the **QA** tab, they can:
1. Provide a Bug Name and assign a `BugSeverity` marker.
2. Tap "Generate Report".
3. BlackBox compiles a robust `toMarkdown()` dossier that formats their OS, device physical DPI, network state, all their past tap events (User Journey), any captured unhandled Dart crashes, and failed network fetches.
4. One Tap `"Copy"` pastes this beautifully formatted report onto their clipboard, perfectly designed for instantly pasting into GitHub Issues, Jira, or Slack.

## 📄 License

MIT.
