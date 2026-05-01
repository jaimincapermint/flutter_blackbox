# Changelog

## [0.3.5] - 2026-05-01

### Fixed
- **Missing File Compile Error**: Added deprecation shims for `lib/adapters/dio.dart`, `http.dart`, `shared_prefs.dart`, and `socket_io.dart`. This prevents fatal compilation errors for users upgrading from v0.2.x who still have the old import paths in their projects.
- **Migration Guide**: Corrected the CHANGELOG migration guide which incorrectly told users to import the deleted adapter files.

## [0.3.4] - 2026-04-29

### Fixed
- Pinned `connectivity_plus` to `>=7.0.0 <7.1.0` to resolve an iOS compile error
  (`Value of type 'NWPath' has no member 'isUltraConstrained'`) introduced in `7.1.x`.
  That API is only available on iOS 16+ but was used without an `#available` check,
  breaking apps with lower minimum deployment targets.

## [0.3.3] - 2026-04-29

### Fixed
- **CLI `--generate` duplicate `httpAdapters` key** — when both `dio` and `http` were present
  in `pubspec.yaml`, the generator emitted two separate `httpAdapters:` named arguments inside
  `BlackBox.setup()`, which is a Dart compile error. Both adapters are now merged into a single
  `httpAdapters: [DioBlackBoxAdapter(dio), HttpBlackBoxAdapter(httpClient)]` list.
- **CLI `--generate` imports placed after class bodies** — each adapter template previously
  embedded its own `import` statements at the top of the template string. When two or more
  adapters were generated into the same file, the second template's imports appeared *after*
  the first template's class declarations — invalid Dart. The generator now collects all
  imports first (deduplicated), writes them at the top of the file, then writes all class
  bodies. `dart:convert` is no longer duplicated when both Dio and http adapters are present.
- **`HttpBlackBoxAdapter._sanitiseHeaders` return type** — the return type was incorrectly
  declared as `Map<String, dynamic>` instead of `Map<String, String>`, inconsistent with
  the Dio adapter and the `NetworkRequest.headers` field. Fixed to `Map<String, String>`.
- **CLI printed hint also had duplicate `httpAdapters`** — the non-`--generate` setup hint
  printed to the terminal suffered the same duplication. The hint now groups all HTTP adapters
  into one `httpAdapters:` line.

---

## [0.3.2] - 2026-04-28

### Fixed
- Upgraded `connectivity_plus` to `^7.1.0` (v7.1.x migrated web implementation to
  `package:web` instead of `dart:html`, restoring WASM compatibility on pub.dev).
- `device_info_plus` and `package_info_plus` upgraded to latest patch via `dart pub upgrade`
  (`12.4.0` and `9.0.1` respectively).

---

## [0.3.1] - 2026-04-28

### Fixed
- Widened dependency constraints to support latest major versions and restore full pub.dev score:
  - `package_info_plus`: `>=9.0.0 <11.0.0` (was `^9.0.0`, now supports v10.x)
  - `device_info_plus`: `>=12.3.0 <14.0.0` (was `^12.3.0`, now supports v13.x)
  - `connectivity_plus`: `>=7.0.0 <8.0.0` (was `^7.0.0`, explicit upper bound)
  - All APIs used (`DeviceInfoPlugin`, `PackageInfo.fromPlatform`, `Connectivity.checkConnectivity`) are stable and unchanged between these major versions.

---

## [0.3.0] - 2026-04-28

### Added
- **CLI Init Tool** — `dart run flutter_blackbox:init` auto-detects your project's dependencies (Dio, http, Socket.IO, SharedPreferences) and prints the exact setup code you need.
  - `--generate` flag generates a `lib/blackbox_adapters.dart` file with **only** the adapters your project uses — zero unnecessary packages installed.
  - `--help` for full usage instructions.
- **CLI-generated adapter architecture** — concrete adapter implementations (DioBlackBoxAdapter, HttpBlackBoxAdapter, SocketIOBlackBoxAdapter, SharedPrefsStorageAdapter) are no longer bundled inside `lib/`. They are generated into the user's project by the CLI. This means:
  - `flutter_blackbox` has **zero optional dependencies** — 63 KB total package size.
  - Dio users don't get `http`, `socket_io_client`, or `shared_preferences` installed.
  - The generated `lib/blackbox_adapters.dart` is fully editable and customizable.
  - Same zero-setup pattern as `build_runner`, `freezed`, and `injectable`.
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
- Main barrel (`flutter_blackbox.dart`) exports only abstract interfaces (`BlackBoxHttpAdapter`, `BlackBoxSocketAdapter`, `BlackBoxStorageAdapter`). Concrete adapter implementations are generated into the user's project by the CLI.
- Moved `dio`, `http`, `shared_preferences`, `socket_io_client` from `dependencies` to `dev_dependencies` — users only install what they actually use.
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
- Concrete adapter classes (`DioBlackBoxAdapter`, `HttpBlackBoxAdapter`, etc.) are no longer
  shipped inside the package. They are now generated directly into your project by the CLI:
  ```sh
  # 1. Generate adapters (detects your pubspec.yaml dependencies automatically)
  dart run flutter_blackbox:init --generate
  ```
  ```dart
  // 2. Replace old adapter imports with the generated file
  // Before (v0.2.x)
  import 'package:flutter_blackbox/adapters/dio.dart';

  // After (v0.3.0+)
  import 'blackbox_adapters.dart';  // generated by CLI
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
