# Changelog

## [0.3.0] - 2026-04-28

### Added
- **CLI Init Tool** — `dart run flutter_blackbox:init` auto-detects your project's dependencies (Dio, http, Socket.IO, SharedPreferences) and prints the exact setup code you need.
  - `--generate` flag creates a ready-to-use `lib/blackbox_setup.dart` file.
  - `--help` for full usage instructions.
- **Modular adapter imports** — adapters are now imported via separate paths to avoid pulling unused dependencies:
  - `import 'package:flutter_blackbox/adapters/dio.dart';`
  - `import 'package:flutter_blackbox/adapters/http.dart';`
  - `import 'package:flutter_blackbox/adapters/socket_io.dart';`
  - `import 'package:flutter_blackbox/adapters/shared_prefs.dart';`
- **Copy as cURL** — one-tap button in Network panel copies any request as a valid `curl` command (with headers, body, method).
- **Status Code Filtering** — filter chips to show only 2xx, 4xx, 5xx, Pending, or Failed requests.
- **Method Filtering** — filter by HTTP method (GET, POST, PUT, DELETE, PATCH).
- **Response Size Display** — shows response body size (B/KB/MB) in each network tile and detail view.
- **Request Timing Visualization** — color-coded timing bars (green < 300ms, yellow < 1000ms, red > 1000ms) with speed indicator.
- **Pretty JSON Viewer** — collapsible, syntax-highlighted JSON tree with color-coded types. Auto-expands first level.
- **Search Across All Panels** — new "Search" tab that queries Network, Logs, Crashes, and Socket events simultaneously.
- **Full Dartdoc Coverage** — all public APIs, stores, and models now have comprehensive documentation for better IDE support and higher pub.dev scoring.
- **Web Compatibility** — removed `dart:io` dependencies from UI panels to ensure the package runs smoothly on Flutter Web.

### Changed
- **Full "devkit" → "BlackBox" rebrand** — all file names, imports, internal references, and the overlay badge now use the BlackBox name consistently.
- Main barrel (`flutter_blackbox.dart`) no longer auto-exports concrete adapter implementations. Import adapters separately via `lib/adapters/` paths.
- Overlay badge now shows "BlackBox" instead of "devkit".
- Internal Dio extras keys renamed from `devkit_request_id`/`devkit_start_ms` to `blackbox_request_id`/`blackbox_start_ms`.
- `NetworkResponse` model now includes optional `responseSizeBytes` field and `formattedSize` getter.
- Dio and HTTP adapters now capture response size automatically.
- Network panel detail view reorganized with timing summary card, collapsible JSON sections, and action buttons (cURL, Copy URL, Copy All).

### Fixed
- Fixed duplicate property definitions in `BlackBox` singleton class.
- Fixed flaky broadcast stream tests in `NetworkStore` by accounting for event throttling.
- Added missing exports for `JourneyEvent`, `FpsMonitor`, and `BlackBoxDeviceInfo` to the main barrel file.

### Performance
- **`NetworkPanel`**: Replaced two independent `StreamBuilder`s on the same stream with a single `StreamSubscription`. Previously every network event triggered two separate rebuild cycles; now it triggers one.
- **`_NetworkTile`**: Cached the `Uri.parse()` result as `late final _endpoint` in `initState`/`didUpdateWidget`. URI parsing no longer runs on every `build()` call.
- **`_CollapsibleJsonSection`**: Replaced the `_parsed` computed getter with a `late final` field set in `initState`. `jsonDecode` now runs once per section lifecycle instead of on every rebuild.
- **`RebuildPanel`**: Converted to `StatefulWidget` + `StreamSubscription`. Removed the `Stream.value(...)` anti-pattern and the `(context as Element).markNeedsBuild()` framework hack.

### Migration
- If you previously used `import 'package:flutter_blackbox/flutter_blackbox.dart'` and relied on Dio/http/Socket/Storage adapters being auto-exported, add the specific adapter import:
  ```dart
  // Before (v0.2.x) — everything from one import
  import 'package:flutter_blackbox/flutter_blackbox.dart';

  // After (v0.3.0) — add adapter imports you need
  import 'package:flutter_blackbox/flutter_blackbox.dart';
  import 'package:flutter_blackbox/adapters/dio.dart';         // if using Dio
  import 'package:flutter_blackbox/adapters/shared_prefs.dart'; // if using SharedPreferences
  ```


## [0.2.2] - 2026-04-06

### Fixed
- Added CHANGELOG updates and minor version bumps for successful pub.dev publication.

## [0.2.1] - 2026-04-06

### Added
- **`ignoredRebuildWidgets` config** in `BlackBox.setup()` to allow overriding and muting noisy custom 3rd-party widgets in the Rebuild tab.
- **Smart Noise Filters** hardcoded over 100+ native Flutter framework base widgets (`Text`, `AutomaticKeepAlive`, `Container`, etc) and 60fps animators (`LinearProgressIndicator`) from tracking to prevent noise.

### Fixed
- Corrected regex string parsing for Flutter framework's raw rebuild log output (`Building`/`Rebuilding`) so Rebuild Tracking accurately measures widget rebuilds rather than staying at zero.
- Rebuild Tracker console spam fixed. Intercepted framework logs are now securely routed to the UI tab while completely muted from terminal output for cleaner logging.
- Fixed infinite rendering loops where `BlackBoxOverlay` and `RebuildTrackerWidget` recursively logged themselves in the Rebuild store.

## [0.2.0] - 2026-03-24

### Added
- **Storage Inspector** — inspect, search, edit, delete key-value pairs from any storage backend.
  - Built-in `SharedPrefsStorageAdapter`.
  - Adapter pattern (`BlackBoxStorageAdapter`) supports GetStorage, Hive, FlutterSecureStorage, etc.
- **Privacy & Sensitive Data Redaction** — keys matching common patterns (password, token, secret, jwt, etc.) auto-redacted.
  - Global toggle: `redactSensitiveData` in `BlackBox.setup()` (default: `true`).
  - 25+ built-in sensitive patterns, customizable per adapter.
  - Sensitive values show as `••••••••` — can't be copied or edited.
- **Widget Rebuild Tracker** — track widget rebuild counts for performance bottlenecks.
  - Auto mode: `debugPrintRebuildDirtyWidgets` hook — zero code changes.
  - Manual mode: `RebuildTracker` widget wrapper (zero-cost in release builds via `kDebugMode`).
- **Socket.IO Adapter** — auto-capture all incoming socket events via `socket.onAny()`.
  - `SocketIOBlackBoxAdapter(socket)` — no changes to socket code.
- **HttpBlackBoxAdapter** — observe-only adapter that takes your existing `http.Client`.

### Changed
- **Observe-only philosophy** — all adapters now hook into libraries' built-in extension points without replacing trusted code.
- `BlackBoxHttpClient` is now `@Deprecated` — replaced by `HttpBlackBoxAdapter(client)`.

### Removed
- Feature Flags panel and `LocalFlagAdapter` — replaced by Storage Inspector and Rebuild Tracker.

## [0.1.4] - 2026-03-19

### Fixed
- Bumped `dio` lower bounds to `^5.4.0` in `pubspec.yaml` to ensure compatibility with `DioException` and restore pub.dev points.

## [0.1.3] - 2026-03-19

### Changed
- Renamed all public classes from `DevKit` to `BlackBox` to fully align with the new package name.

## [0.1.1] - 2026-03-19

### Changed
- Updated README and internal configuration to correctly reflect the `flutter_blackbox` package name.

## [0.1.0] - 2025-03-19

### Added
- Single-package release — Dio and http adapters bundled in core
- `DevKitOverlay` — tabbed debug panel above Navigator
- Network panel — request/response log with headers and body
- Mock engine — intercept any HTTP request with fake response
- Log panel — captures `debugPrint()` automatically
- Performance panel — live FPS graph and jank detection
- Feature flags panel — runtime toggle without restart
- Device panel — platform, screen, OS info
- QA Report — one-tap screenshot + logs + network bundle
- `DioDevKitAdapter` — Dio interceptor (included in core)
- `DevKitHttpClient` — http.Client drop-in (included in core)
- `PrintLogAdapter` — auto-captures debugPrint
- `LocalFlagAdapter` — in-memory feature flags
