import '../../core/crash/crash_entry.dart';
import '../../core/log/log_entry.dart';
import '../../core/network/network_store.dart';

/// Abstract observer that receives BlackBox events.
///
/// Implement this to forward debug data to external monitoring services
/// like Firebase Crashlytics, Sentry, Datadog, or your own analytics.
///
/// ```dart
/// class CrashlyticsObserver extends BlackBoxObserver {
///   @override
///   void onCrash(CrashEntry crash) {
///     FirebaseCrashlytics.instance.recordError(
///       crash.message,
///       crash.stackTrace,
///       reason: 'Caught by Flutter BlackBox 🐞',
///     );
///   }
/// }
///
/// BlackBox.setup(
///   observers: [CrashlyticsObserver()],
/// );
/// ```
///
/// All methods have empty default implementations — override only what
/// you need.
abstract class BlackBoxObserver {
  /// Called when an uncaught exception or Flutter framework error is captured.
  ///
  /// Use this to forward crashes to services like Crashlytics or Sentry.
  void onCrash(CrashEntry crash) {}

  /// Called for every log entry recorded by BlackBox.
  ///
  /// Includes logs from `BlackBox.log()`, auto-captured `debugPrint`
  /// output, and adapter-generated logs.
  void onLog(LogEntry log) {}

  /// Called when a network request completes with an error status (≥ 400)
  /// or a connection failure.
  ///
  /// Use this to track API reliability or alert on specific endpoints.
  void onNetworkError(NetworkEntry entry) {}

  /// Called when a network request completes successfully.
  ///
  /// Override this only if you need to track all network activity
  /// (e.g., for analytics or performance monitoring).
  void onNetworkResponse(NetworkEntry entry) {}
}
