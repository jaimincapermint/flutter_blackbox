import '../../core/log/log_entry.dart';

/// Interface for capturing and forwarding logs to BlackBox.
abstract class BlackBoxLogAdapter {
  /// Name of the logging library or provider (e.g., 'Logger', 'FLog').
  String get name;

  /// Callback to forward a [LogEntry] to BlackBox.
  void Function(LogEntry)? onLogCallback;

  /// Emits a log entry to the registered callback.
  void emitLog(LogEntry entry) => onLogCallback?.call(entry);

  /// Called to initialize log interception.
  void attach() {}

  /// Called to stop log interception.
  void detach() {}
}
