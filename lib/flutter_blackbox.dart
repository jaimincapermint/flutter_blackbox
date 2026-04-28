/// Flutter BlackBox — In-app debug & QA overlay for Flutter.
///
/// Single package containing the core overlay, all panels, and built-in
/// adapters for Dio and dart:http.
///
/// ## Minimal setup
/// ```dart
/// void main() {
///   BlackBox.setup(enabled: kDebugMode);
///   runApp(BlackBoxOverlay(child: const MyApp()));
/// }
/// ```
///
/// ## With Dio
/// ```dart
/// import 'package:flutter_blackbox/adapters/dio.dart';
///
/// BlackBox.setup(
///   httpAdapters: [DioBlackBoxAdapter(dio)],
///   enabled: kDebugMode,
/// );
/// ```
///
/// ## With http package
/// ```dart
/// import 'package:flutter_blackbox/adapters/http.dart';
///
/// final adapter = HttpBlackBoxAdapter(http.Client());
/// BlackBox.setup(
///   httpAdapters: [adapter],
///   enabled: kDebugMode,
/// );
/// ```
library flutter_blackbox;

// ── Core public API ──────────────────────────────────────────────────────────
export 'src/blackbox.dart';

// ── Overlay ──────────────────────────────────────────────────────────────────
export 'src/overlay/blackbox_overlay.dart';
export 'src/overlay/blackbox_trigger.dart';

// ── Models ───────────────────────────────────────────────────────────────────
export 'src/core/log/log_entry.dart';
export 'src/core/log/log_level.dart';
export 'src/core/crash/crash_entry.dart';
export 'src/core/crash/crash_store.dart';
export 'src/core/journey/journey_event.dart';
export 'src/core/journey/journey_store.dart';
export 'src/core/network/network_request.dart';
export 'src/core/network/network_response.dart';
export 'src/core/network/mock_response.dart';
export 'src/core/socket/socket_event.dart';
export 'src/core/socket/socket_store.dart';
export 'src/core/rebuild/rebuild_store.dart';
export 'src/core/rebuild/rebuild_tracker_widget.dart';
export 'src/core/performance/fps_monitor.dart';
export 'src/core/report/blackbox_report.dart';
export 'src/core/report/blackbox_device_info.dart';

// ── Adapter interfaces (no external deps) ────────────────────────────────────
export 'src/adapters/http/blackbox_http_adapter.dart';
export 'src/adapters/log/blackbox_log_adapter.dart';
export 'src/adapters/log/print_log_adapter.dart';
export 'src/adapters/storage/blackbox_storage_adapter.dart';
export 'src/adapters/socket/blackbox_socket_adapter.dart';

// ── Built-in adapter implementations ─────────────────────────────────────────
// Import these separately to avoid pulling in unused dependencies:
//
//   import 'package:flutter_blackbox/adapters/dio.dart';          // Dio
//   import 'package:flutter_blackbox/adapters/http.dart';         // http
//   import 'package:flutter_blackbox/adapters/socket_io.dart';    // Socket.IO
//   import 'package:flutter_blackbox/adapters/shared_prefs.dart'; // SharedPreferences
