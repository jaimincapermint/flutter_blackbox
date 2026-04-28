import 'log_level.dart';

/// Immutable snapshot of a single log event captured by BlackBox.
class LogEntry {
  const LogEntry({
    required this.id,
    required this.level,
    required this.message,
    required this.timestamp,
    this.tag,
    this.data,
    this.error,
    this.stackTrace,
  });

  /// Unique identifier for the log entry.
  final String id;

  /// Severity level of the log.
  final LogLevel level;

  /// The recorded message.
  final String message;

  /// When the log event occurred.
  final DateTime timestamp;

  /// Optional tag or category label (e.g., 'AuthBloc', 'Network').
  final String? tag;

  /// Arbitrary structured metadata attached to this log.
  final Map<String, dynamic>? data;

  /// Optional error object associated with this log.
  final Object? error;

  /// Optional stack trace associated with this log.
  final StackTrace? stackTrace;

  Map<String, dynamic> toJson() => {
        'id': id,
        'level': level.label,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        if (tag != null) 'tag': tag,
        if (data != null) 'data': data,
        if (error != null) 'error': error.toString(),
        if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      };

  @override
  String toString() => '[${level.label}] ${timestamp.toIso8601String()} '
      '${tag != null ? "[$tag] " : ""}$message';
}
