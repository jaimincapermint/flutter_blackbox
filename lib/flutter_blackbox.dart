/// devkit — In-app debug overlay for Flutter.
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
/// BlackBox.setup(
///   httpAdapters: [DioBlackBoxAdapter(dio)],
///   enabled: kDebugMode,
/// );
/// ```
///
/// ## With http package
/// ```dart
/// BlackBox.setup(
///   httpAdapters: [HttpBlackBoxAdapter()],
///   enabled: kDebugMode,
/// );
/// // Use BlackBoxHttpClient() instead of http.Client()
/// final client = BlackBoxHttpClient();
/// ```
library devkit;

// ── Core public API ──────────────────────────────────────────────────────────
export 'src/devkit.dart';

// ── Overlay ──────────────────────────────────────────────────────────────────
export 'src/overlay/devkit_overlay.dart';
export 'src/overlay/devkit_trigger.dart';

// ── Models ───────────────────────────────────────────────────────────────────
export 'src/core/log/log_entry.dart';
export 'src/core/log/log_level.dart';
export 'src/core/crash/crash_entry.dart';
export 'src/core/crash/crash_store.dart';
export 'src/core/network/network_request.dart';
export 'src/core/network/network_response.dart';
export 'src/core/network/mock_response.dart';
export 'src/core/flags/flag_config.dart';
export 'src/core/flags/flag_type.dart';
export 'src/core/report/devkit_report.dart';

// ── Adapter interfaces (implement for custom HTTP clients) ───────────────────
export 'src/adapters/http/devkit_http_adapter.dart';
export 'src/adapters/log/devkit_log_adapter.dart';
export 'src/adapters/flag/devkit_flag_adapter.dart';

// ── Built-in adapters ────────────────────────────────────────────────────────
export 'src/adapters/log/print_log_adapter.dart';
export 'src/adapters/flag/local_flag_adapter.dart';

// ── Dio adapter (requires dio: ">=5.0.0 <6.0.0" in your pubspec) ────────────
export 'src/adapters/dio/dio_devkit_adapter.dart';

// ── dart:http adapter (requires http: ">=1.0.0 <2.0.0" in your pubspec) ─────
export 'src/adapters/http_client/http_devkit_adapter.dart';
export 'src/adapters/http_client/devkit_http_client.dart';
