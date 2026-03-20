import '../../core/log/log_entry.dart';

/// Implement to forward log events from your logging library to BlackBox.
abstract class BlackBoxLogAdapter {
  String get name;

  /// Set by BlackBox — call this when a log event is produced.
  void Function(LogEntry)? onLogCallback;

  void emitLog(LogEntry entry) => onLogCallback?.call(entry);

  void attach() {}
  void detach() {}
}
