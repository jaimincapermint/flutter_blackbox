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

  final String id;
  final LogLevel level;
  final String message;
  final DateTime timestamp;

  /// Optional tag / source label e.g. 'AuthBloc', 'ApiService'.
  final String? tag;

  /// Arbitrary structured data attached to this log event.
  final Map<String, dynamic>? data;

  final Object? error;
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
