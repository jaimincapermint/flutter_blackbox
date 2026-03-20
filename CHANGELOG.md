# Changelog

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
